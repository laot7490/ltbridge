import crypto from "node:crypto";
import { version } from "../../package.json";
import { applyBuildConstants } from "../lua/constants";
import { mapLuaCode, stripLuaForScan } from "../lua/source";
import { getModuleData, SIDES, type Side, type StubMetadata } from "../catalog/database";
import type { ProjectConfig } from "../project/config";

export function renderBundle(loadSequence: string[], config: ProjectConfig) {
	const doMinify = config.minify === true;
	const buildAsIndividual = config.bundle !== true;
	const emitted = new Set<Side>();

	const funcNamespaceMap: Record<string, string | null> = Object.create(null);
	const funcMetadata: Record<string, StubMetadata> = Object.create(null);
	const collectedSources: (Record<Side, string> & { moduleId: string })[] = [];

	const processModule = (modName: string) => {
		const modData = getModuleData(modName);
		if (!modData) return;
		const ns = modData.ns;

		const collectSideSource = (fileType: Side) => {
			const ctxData = modData[fileType];
			if (ctxData) {
				if (ctxData.stubs) {
					for (const stub of ctxData.stubs) {
						funcNamespaceMap[stub.funcName] = ns;
						funcMetadata[stub.funcName] = stub.metadata;
					}
				}
				const content = ctxData.code;
				const header = `\n-- Module: ${modName} (${fileType}.lua)\n`;
				let finalContent = content;
				if (!doMinify && !buildAsIndividual) {
					finalContent = mapLuaCode(content, (code, offset) => code.replace(/(^|\n)(?=[^\r\n]*\S)/g, (line, before, index) => index > 0 || before || offset === 0 ? line + "\t" : line));
				}
				if (!buildAsIndividual) return header + `do\n${finalContent}\nend\n`;
				return `${finalContent}\n`;
			}
			return null;
		};

		const sources = { moduleId: modName, shared: "", client: "", server: "" };
		for (const side of SIDES) {
			const code = collectSideSource(side);
			if (!code) continue;
			sources[side] = code;
			emitted.add(side);
		}
		collectedSources.push(sources);
	};

	for (const modName of loadSequence) {
		processModule(modName);
	}

	const luamin = (doMinify ? require("../vendor/luamin.cjs") : undefined);
	const minifySafe = (source: string, name: string): string => {
		if (!doMinify) return source;
		try {
			return luamin.Minify(source, { RenameVariables: true, RenameGlobals: false, SolveMath: false });
		} catch (e) {
			console.log(`\x1b[33m! Minification failed for ${name}. Emitting unminified code. Error: ${e instanceof Error ? e.message : e}\x1b[0m`);
			return source;
		}
	};

	const GLOBAL_BLACKLIST = ["LT", "QBCore", "ESX", "QBX", "exports"];
	const globalsToRandomize = new Set<string>();
	const collectGlobals = (source: string) => {
		source = stripLuaForScan(source);
		const globalRegex = /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=/gm;
		let match;
		while ((match = globalRegex.exec(source)) !== null) {
			const g = match[1];
			if (!GLOBAL_BLACKLIST.includes(g)) globalsToRandomize.add(g);
		}
	};

	const disableDebug = config.debug === false || config.debug === undefined;
	for (const mod of collectedSources) {
		if (mod.shared) {
			mod.shared = applyBuildConstants(mod.shared, { version, disableDebug });
		}
	}

	if (doMinify) {
		for (const mod of collectedSources) {
			if (mod.shared) collectGlobals(mod.shared);
			if (mod.client) collectGlobals(mod.client);
			if (mod.server) collectGlobals(mod.server);
		}
	}
	const hashObj = (str: string) => crypto.createHash("md5").update(str).digest("hex").substring(0, 5);
	const globalMappings: Record<string, string> = Object.create(null);
	const usedNames = new Set();

	function allocateGlobal(name: string) {
		let h = hashObj(name);
		let index = 0;
		while (usedNames.has(h)) {
			index++;
			h = hashObj(name + index);
		}
		usedNames.add(h);
		return globalMappings[name] = `__` + h;
	}

	for (const name of globalsToRandomize) allocateGlobal(name);

	const globalKeys = Object.keys(globalMappings);
	const globalPattern = globalKeys.length > 0 ? new RegExp(`\\b(${globalKeys.join("|")})\\b`, "g") : null;
	const randomizeGlobals = (source: string) => {
		if (!globalPattern) return source;
		return mapLuaCode(source, (code) => code.replace(globalPattern, (name) => globalMappings[name]));
	};

	if (doMinify) {
		for (const mod of collectedSources) {
			mod.shared = randomizeGlobals(mod.shared);
			mod.client = randomizeGlobals(mod.client);
			mod.server = randomizeGlobals(mod.server);
		}
	}

	const bundleRequiredTables = {
		shared: new Set<string>(),
		client: new Set<string>(),
		server: new Set<string>(),
	};

	const rules = Object.keys(funcNamespaceMap).sort((a, b) => b.length - a.length).map((name) => {
		const ns = funcNamespaceMap[name];
		const prefix = ns ? `LT.${ns}.` : "LT.";
		return {
			name,
			ns,
			prefix,
			meta: funcMetadata[name],
			internal: new RegExp(`(^|[^a-zA-Z0-9_.:"'])(${name})(\\s*[=().,\\[\\]])`, "g"),
			declaration: new RegExp(`(^[ \\t]*function\\s+)${name}(\\s*\\()`, "gm"),
			normalize: new RegExp(`\\b${prefix.replaceAll(".", "\\.")}(${name})(\\s*\\()`, "g"),
			call: new RegExp(`(^|[^a-zA-Z0-9_.:"'])(${name})(\\s*\\()`, "g"),
		};
	});
	const injectLTNamespace = (source: string, targetRequiredTables: Set<string> | null) => {
		if (!source) return source;
		if (rules.length === 0) return source;

		const rewrites: ((code: string) => string)[] = [];
		const requiredTables = new Set<string>();
		let extraExports = "";
		const identifiers = new Set(stripLuaForScan(source).match(/[a-zA-Z_][a-zA-Z0-9_]*/g));

		for (const { name, ns, prefix: origPrefixStr, meta, internal, declaration, normalize, call } of rules) {
			if (!identifiers.has(name)) continue;

			if (doMinify && meta.internal) {
				const targetReplacement = globalMappings[name] ?? allocateGlobal(name);
				rewrites.push((code) => code.replace(internal, `$1${targetReplacement}$3`));
				continue;
			}

			let targetReplacement = `${origPrefixStr}${name}`;
			let needsNsTable = ns ? true : false;

			if (meta.export) {
				targetReplacement = `${origPrefixStr}${meta.export}`;
				if (meta.global) {
					const gName = meta.global === true ? meta.export : meta.global;
					extraExports += `LT.${gName} = ${targetReplacement}\n`;
				}
			} else if (meta.global) {
				const gName = meta.global === true ? name : meta.global;
				targetReplacement = `LT.${gName}`;
				needsNsTable = false;
			}

			if (needsNsTable) {
				if (targetRequiredTables) {
					targetRequiredTables.add(`LT.${ns} = LT.${ns} or {}`);
				} else {
					requiredTables.add(`LT.${ns} = LT.${ns} or {}`);
				}
			}

			if (meta.alias) {
				meta.alias.forEach((al) => {
					extraExports += `${origPrefixStr}${al} = ${targetReplacement}\n`;
				});
			}

			rewrites.push((code) => code.replace(declaration, `$1${targetReplacement}$2`).replace(normalize, "$1$2").replace(call, (m, prefix, _func, suffix) => {
				if (prefix.trim().endsWith("function")) return m;
				return `${prefix}${targetReplacement}${suffix}`;
			}));
		}

		const newSource = rewrites.length ? mapLuaCode(source, (code) => rewrites.reduce((result, rewrite) => rewrite(result), code)) : source;
		if (targetRequiredTables) {
			return newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		} else {
			const initStr = `LT = LT or {}\n` + Array.from(requiredTables).join("\n") + (requiredTables.size > 0 ? `\n\n` : `\n`);
			return initStr + newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		}
	};

	const finalBundle = { shared: "", client: "", server: "" };
	const individualFiles: { path: string; content: string; type: Side }[] = [];
	for (const sources of collectedSources) {
		for (const side of SIDES) {
			if (!sources[side]) continue;
			const code = injectLTNamespace(sources[side], buildAsIndividual ? null : bundleRequiredTables[side]);
			const content = minifySafe(code, sources.moduleId + " " + side + ".lua");
			if (buildAsIndividual) {
				individualFiles.push({ path: getIndividualPath(sources.moduleId, side), content, type: side });
			} else finalBundle[side] += content + "\n";
		}
	}

	const outputs = new Map<string, string>();
	const writeOutput = (relativePath: string, content: string) => outputs.set(relativePath, content);

	const getBundleHeader = (type: string) =>
		`--[[\n * @license LT Bridge\n * ${type.toLowerCase()}.lua\n *\n * Copyright (c) LT Scripts.\n *\n * This source code is licensed under the MIT license found in the\n * LICENSE file in the root directory of this source tree.\n]]\n\n`;

	if (buildAsIndividual) {
		const loaders: Record<Side, string[]> = { shared: [], client: [], server: [] };

		for (const file of individualFiles) {
			const relPath = "modules/" + file.path.replace(/\\/g, "/");
			writeOutput(relPath, getBundleHeader(file.type) + "--- @diagnostic disable\n" + file.content);
			const requirePath = file.path.replace(/\\/g, "/").replace(/^imports\//, "");
			loaders[file.type].push(`    "${requirePath}"`);
		}

		const generateLoader = (typeStr: string, items: string[]) => {
			if (items.length === 0) return "";
			return `-- LTBridge Auto-Generated ${typeStr} Loader

local RESOURCE <const> = GetCurrentResourceName()
local BASE_PATH <const> = "ltbridge/modules/imports/"

local modules = {
${items.join(",\n")}
}

local function loadModule(path)
    local fullPath = BASE_PATH .. path
    local content = LoadResourceFile(RESOURCE, fullPath)
    if not content then
        return print(("^6[LTBridge ${version}] ^1ERROR: Module file not found: %s^7"):format(path))
    end
    local chunk, err = load(content, ("@@%s/%s"):format(RESOURCE, fullPath))
    if not chunk then
        return print(("^6[LTBridge ${version}] ^1ERROR: Syntax error in module: %s\\n%s^7"):format(fullPath, err))
    end
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        print(("^6[LTBridge ${version}] ^1ERROR: Runtime error in module: %s\\n%s^7"):format(fullPath, runtimeErr))
    end
end

for i = 1, #modules do
    loadModule(modules[i])
end
`;
		};

		if (emitted.has("shared")) writeOutput("modules/shared.lua", generateLoader("Shared", loaders.shared));
		if (emitted.has("client")) writeOutput("modules/client.lua", generateLoader("Client", loaders.client));
		if (emitted.has("server")) writeOutput("modules/server.lua", generateLoader("Server", loaders.server));
	} else {
		const getInitBlock = (type: Side) =>
			`LT = LT or {}\n` +
			Array.from(bundleRequiredTables[type]).join("\n") +
			(bundleRequiredTables[type].size > 0 ? `\n\n` : `\n`);

		if (emitted.has("shared"))
			writeOutput(
				"modules/shared.lua",
				getBundleHeader("Shared") + "--- @diagnostic disable\n" + getInitBlock("shared") + finalBundle.shared,
			);
		if (emitted.has("client"))
			writeOutput(
				"modules/client.lua",
				getBundleHeader("Client") + "--- @diagnostic disable\n" + getInitBlock("client") + finalBundle.client,
			);
		if (emitted.has("server"))
			writeOutput(
				"modules/server.lua",
				getBundleHeader("Server") + "--- @diagnostic disable\n" + getInitBlock("server") + finalBundle.server,
			);
	}

	return { outputs, hasClient: emitted.has("client"), hasServer: emitted.has("server"), hasShared: emitted.has("shared") };
}

function getIndividualPath(modName: string, type: Side) {
	const modParts = modName.split("/");
	let category = "uncategorized";
	let name = modName;
	if (modName === "__init__") {
		category = "Core";
		name = "init";
	} else if (modParts.length > 1) {
		category = modParts.slice(0, -1).join("/").replace(/^@/, "");
		name = modParts[modParts.length - 1];
	} else if (modName.startsWith("@")) {
		category = modName.replace(/^@/, "");
		name = "init";
	} else {
		name = modName.replace(/^@/, "");
	}
	return name === "init" ? `imports/${category}/${type}.lua` : `imports/${category}/${name}/${type}.lua`;
}
