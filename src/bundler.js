const fs = require("fs-extra");
const path = require("path");
const { applyBuildConstants } = require("./buildConstants");

let _exportMapCache = null;
function getModuleExportMap() {
	if (_exportMapCache) return _exportMapCache;
	const { getDatabase } = require("./registry");
	_exportMapCache = getDatabase().exportMap;
	return _exportMapCache;
}

function generateFullApi(targetDir) {
	const { getDatabase } = require("./registry");
	const db = getDatabase();
	const apiStubs = [];
	const requiredTables = new Set();
	const typeMap = new Map();

	for (const [modName, modData] of Object.entries(db.modules)) {
		if (modData.ns) requiredTables.add(`LT.${modData.ns} = LT.${modData.ns} or {}`);

		const processTypes = (ctxData) => {
			if (!ctxData || !ctxData.types) return;
			for (const typeEntry of ctxData.types) {
				if (typeEntry && typeEntry.className && typeEntry.code) {
					typeMap.set(typeEntry.className, typeEntry.code);
				}
			}
		};
		const processCtx = (ctxData) => {
			if (ctxData && ctxData.stubs) {
				for (const stub of ctxData.stubs) {
					if (stub.stubCode && !stub.metadata.internal) {
						apiStubs.push(stub.stubCode);
					}
				}
			}
		};
		processTypes(modData.shared);
		processTypes(modData.client);
		processTypes(modData.server);
		processCtx(modData.shared);
		processCtx(modData.client);
		processCtx(modData.server);
	}

	const ltModulesDir = path.join(targetDir, "ltbridge");
	fs.ensureDirSync(ltModulesDir);

	const apiHeader = `--- @meta\n--- LT Bridge API Reference\n--- Auto-generated stub file for IDE intellisense.\n--- Do NOT include this file in your fxmanifest.\n\n`;
	const initBlock = `LT = LT or {}\n` + Array.from(requiredTables).sort().join("\n") + "\n\n";
	const typesBlock = typeMap.size > 0 ? Array.from(typeMap.values()).join("\n\n") + "\n\n" : "";
	const apiContent = apiHeader + initBlock + typesBlock + apiStubs.join("\n\n") + "\n";

	fs.writeFileSync(path.join(ltModulesDir, "api.lua"), apiContent);
}

function rebuildBundle(targetDir, config, options = {}) {
	const { version } = require("../package.json");
	const skipApi = options.skipApi === true;

	if (config.version !== version) {
		if (!skipApi) {
			console.log(
				`\x1b[36mℹ LTBridge version updated (${config.version || "unknown"} -> ${version}). Regenerating API stubs...\x1b[0m`,
			);
			generateFullApi(targetDir);
		} else {
			console.log(
				`\x1b[36mℹ LTBridge version updated (${config.version || "unknown"} -> ${version}). Run 'ltbridge api' to refresh API stubs.\x1b[0m`,
			);
		}
		config.version = version;
		const configPath = path.join(targetDir, "ltbridge", "ltbridge.config.json");
		fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
	}

	const startTime = Date.now();
	const explicitModules = config.modules || [];
	const doMinify = config.minify === true;
	const buildAsIndividual = config.buildAsBundle !== true;

	let loadSequence = [];
	const { resolveDependencies } = require("./moduleResolver");

	if (explicitModules.length > 0) {
		const result = resolveDependencies(explicitModules, getModuleExportMap());
		loadSequence = result.sequence;
	}

	loadSequence = ["__init__", ...loadSequence.filter((m) => m !== "__init__")];

	const { getModuleData } = require("./registry");

	let hasClient = false;
	let hasServer = false;
	let hasShared = false;

	const funcNamespaceMap = {};
	const funcMetadata = {};
	const collectedSources = [];

	const processModule = (modName) => {
		const modData = getModuleData(modName);
		if (!modData) return;
		const ns = modData.ns;

		const checkAndAppend = (fileType) => {
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
				if (!doMinify) {
					finalContent = content
						.split("\n")
						.map((line) => (line.trim().length > 0 && !buildAsIndividual ? "\t" + line : line))
						.join("\n");
				}
				if (!buildAsIndividual) return header + `do\n${finalContent}\nend\n`;
				return `${finalContent}\n`;
			}
			return null;
		};

		const newShared = checkAndAppend("shared");
		const newClient = checkAndAppend("client");
		const newServer = checkAndAppend("server");

		if (newShared || newClient || newServer) {
			collectedSources.push({
				modName,
				ns,
				shared: newShared || "",
				client: newClient || "",
				server: newServer || "",
			});
			if (newShared) hasShared = true;
			if (newClient) hasClient = true;
			if (newServer) hasServer = true;
		}
	};

	if (options.details) {
		console.log(`\n\x1b[1m\x1b[35m📦 Bundling Sequence (${loadSequence.length} modules):\x1b[0m`);
		loadSequence.forEach((mod, index) => console.log(`  \x1b[90m${(index + 1).toString().padStart(2, "0")}.\x1b[0m ${mod}`));
		console.log("");
	}

	for (const modName of loadSequence) {
		processModule(modName);
	}

	const luamin = require("./luamin");
	const minifySafe = (source, name) => {
		if (!doMinify) return source;
		try {
			return luamin.Minify(source, { RenameVariables: true, RenameGlobals: false, SolveMath: false });
		} catch (e) {
			console.log(`\x1b[33m! Minification failed for ${name}. Emitting unminified code. Error: ${e.message}\x1b[0m`);
			return source;
		}
	};

	const GLOBAL_BLACKLIST = ["LT", "QBCore", "ESX", "QBX", "exports"];
	const globalsToRandomize = new Set();
	const collectGlobals = (source) => {
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

	const crypto = require("crypto");
	const hashObj = (str) => crypto.createHash("md5").update(str).digest("hex").substring(0, 5);
	const globalMappings = {};
	const usedNames = new Set();

	for (const g of globalsToRandomize) {
		let h = hashObj(g);
		let index = 0;
		while (usedNames.has(h)) {
			index++;
			h = hashObj(g + index);
		}
		usedNames.add(h);
		globalMappings[g] = `__` + h;
	}

	const randomizeGlobals = (source) => {
		if (!source) return source;
		const keys = Object.keys(globalMappings);
		if (keys.length === 0) return source;
		const escaped = keys.sort((a, b) => b.length - a.length).map((k) => k.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
		const megaRegex = new RegExp(
			`\\[\\[[\\s\\S]*?\\]\\]|'(?:[^'\\\\]|\\\\.)*'|"(?:[^"\\\\]|\\\\.)*"|\\b(${escaped.join("|")})\\b`,
			"g",
		);
		return source.replace(megaRegex, (match, captured) => {
			if (captured && globalMappings[captured]) return globalMappings[captured];
			return match;
		});
	};

	if (doMinify) {
		for (const mod of collectedSources) {
			mod.shared = randomizeGlobals(mod.shared);
			mod.client = randomizeGlobals(mod.client);
			mod.server = randomizeGlobals(mod.server);
		}
	}

	const bundleRequiredTables = {
		shared: new Set(),
		client: new Set(),
		server: new Set(),
	};

	const injectLTNamespace = (source, targetRequiredTables) => {
		if (!source) return source;
		const sortedNames = Object.keys(funcNamespaceMap).sort((a, b) => b.length - a.length);
		if (sortedNames.length === 0) return source;

		let newSource = source;
		const requiredTables = new Set();
		let extraExports = "";

		for (const name of sortedNames) {
			const ns = funcNamespaceMap[name];
			const origPrefixStr = ns ? `LT.${ns}.` : `LT.`;
			const meta = funcMetadata[name] || {};

			if (doMinify && meta.internal) {
				if (!globalMappings[name]) {
					let h = hashObj(name);
					let index = 0;
					while (usedNames.has(h)) {
						index++;
						h = hashObj(name + index);
					}
					usedNames.add(h);
					globalMappings[name] = `__` + h;
				}
				const targetReplacement = globalMappings[name];
				const callRegex = new RegExp(`(^|[^a-zA-Z0-9_.:"'])(${name})(\\s*[=().,\\[\\]])`, "g");
				newSource = newSource.replace(callRegex, `$1${targetReplacement}$3`);
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

			const existsInSource = new RegExp(`\\b${name}\\b`).test(source);
			if (needsNsTable && existsInSource) {
				if (targetRequiredTables) {
					targetRequiredTables.add(`LT.${ns} = LT.${ns} or {}`);
				} else {
					requiredTables.add(`LT.${ns} = LT.${ns} or {}`);
				}
			}

			if (meta.alias && existsInSource) {
				meta.alias.forEach((al) => {
					extraExports += `${origPrefixStr}${al} = ${targetReplacement}\n`;
				});
			}

			if (!existsInSource) continue;

			const declRegex = new RegExp(`(^[ \\t]*function\\s+)${name}(\\s*\\()`, "gm");
			newSource = newSource.replace(declRegex, `$1${targetReplacement}$2`);

			const exactPrefixEscaped = origPrefixStr.replace(/\./g, "\\.");
			const normRegex = new RegExp(`\\b${exactPrefixEscaped}(${name})(\\s*\\()`, "g");
			newSource = newSource.replace(normRegex, `$1$2`);

			const callRegex = new RegExp(`(^|[^a-zA-Z0-9_.:"'])(${name})(\\s*\\()`, "g");
			newSource = newSource.replace(callRegex, (m, prefix, func, suffix) => {
				if (prefix.trim().endsWith("function")) return m;
				return `${prefix}${targetReplacement}${suffix}`;
			});
		}

		if (targetRequiredTables) {
			return newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		} else {
			const initStr = `LT = LT or {}\n` + Array.from(requiredTables).join("\n") + (requiredTables.size > 0 ? `\n\n` : `\n`);
			return initStr + newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		}
	};

	let finalBundle = { shared: "", client: "", server: "" };
	let individualFiles = [];

	for (const mod of collectedSources) {
		mod.shared = injectLTNamespace(mod.shared, !buildAsIndividual ? bundleRequiredTables.shared : null);
		mod.client = injectLTNamespace(mod.client, !buildAsIndividual ? bundleRequiredTables.client : null);
		mod.server = injectLTNamespace(mod.server, !buildAsIndividual ? bundleRequiredTables.server : null);

		if (buildAsIndividual) {
			if (mod.shared)
				individualFiles.push({
					path: getIndividualPath(mod.modName, "shared"),
					content: minifySafe(mod.shared, `${mod.modName} shared.lua`),
					type: "shared",
					ns: mod.ns,
				});
			if (mod.client)
				individualFiles.push({
					path: getIndividualPath(mod.modName, "client"),
					content: minifySafe(mod.client, `${mod.modName} client.lua`),
					type: "client",
					ns: mod.ns,
				});
			if (mod.server)
				individualFiles.push({
					path: getIndividualPath(mod.modName, "server"),
					content: minifySafe(mod.server, `${mod.modName} server.lua`),
					type: "server",
					ns: mod.ns,
				});
		} else {
			if (mod.shared) finalBundle.shared += minifySafe(mod.shared, `${mod.modName} shared.lua`) + "\n";
			if (mod.client) finalBundle.client += minifySafe(mod.client, `${mod.modName} client.lua`) + "\n";
			if (mod.server) finalBundle.server += minifySafe(mod.server, `${mod.modName} server.lua`) + "\n";
		}
	}

	const ltModulesDir = path.join(targetDir, "ltbridge");
	const writtenOutputs = new Set();

	const writeOutput = (relativePath, content) => {
		const rel = relativePath.replace(/\\/g, "/");
		const fullPath = path.join(ltModulesDir, rel);
		fs.ensureDirSync(path.dirname(fullPath));
		if (fs.existsSync(fullPath)) {
			try {
				if (fs.readFileSync(fullPath, "utf8") === content) {
					writtenOutputs.add(rel);
					return;
				}
			} catch {}
		}
		fs.writeFileSync(fullPath, content);
		writtenOutputs.add(rel);
	};

	const readmeContent = `=== LTBridge Auto-Generated Modules ===\nThese files were automatically generated and/or minified by LTBridge.\nRepository: https://github.com/laot7490/ltbridge\nLTBridge Version: ${version}\n`;
	writeOutput("README.txt", readmeContent);

	const { injectManifest } = require("./manifestInjector");
	const getBundleHeader = (type) =>
		`--[[\n * @license LT Bridge\n * ${type.toLowerCase()}.lua\n *\n * Copyright (c) LT Scripts.\n *\n * This source code is licensed under the MIT license found in the\n * LICENSE file in the root directory of this source tree.\n]]\n\n`;

	if (buildAsIndividual) {
		const loaders = { shared: [], client: [], server: [] };

		for (const file of individualFiles) {
			const relPath = "modules/" + file.path.replace(/\\/g, "/");
			writeOutput(relPath, getBundleHeader(file.type) + "--- @diagnostic disable\n" + file.content);
			const requirePath = file.path.replace(/\\/g, "/").replace(/^imports\//, "");
			loaders[file.type].push(`    "${requirePath}"`);
		}

		const generateLoader = (typeStr, items) => {
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

		if (hasShared) writeOutput("modules/shared.lua", generateLoader("Shared", loaders.shared));
		if (hasClient) writeOutput("modules/client.lua", generateLoader("Client", loaders.client));
		if (hasServer) writeOutput("modules/server.lua", generateLoader("Server", loaders.server));
		injectManifest(targetDir, hasClient, hasServer, hasShared, true);
	} else {
		const getInitBlock = (type) =>
			`LT = LT or {}\n` +
			Array.from(bundleRequiredTables[type]).join("\n") +
			(bundleRequiredTables[type].size > 0 ? `\n\n` : `\n`);

		if (hasShared)
			writeOutput(
				"modules/shared.lua",
				getBundleHeader("Shared") + "--- @diagnostic disable\n" + getInitBlock("shared") + finalBundle.shared,
			);
		if (hasClient)
			writeOutput(
				"modules/client.lua",
				getBundleHeader("Client") + "--- @diagnostic disable\n" + getInitBlock("client") + finalBundle.client,
			);
		if (hasServer)
			writeOutput(
				"modules/server.lua",
				getBundleHeader("Server") + "--- @diagnostic disable\n" + getInitBlock("server") + finalBundle.server,
			);
		injectManifest(targetDir, hasClient, hasServer, hasShared, false);
	}

	pruneGeneratedOutputs(ltModulesDir, writtenOutputs);

	console.log(`\x1b[32m✓\x1b[0m ${loadSequence.length} modules bundled in ${Date.now() - startTime}ms`);
}

function pruneGeneratedOutputs(ltModulesDir, writtenOutputs) {
	const modulesDir = path.join(ltModulesDir, "modules");
	if (fs.existsSync(modulesDir)) {
		pruneDirectory(modulesDir, ltModulesDir, writtenOutputs);
	}

	const readmePath = path.join(ltModulesDir, "README.txt");
	if (fs.existsSync(readmePath) && !writtenOutputs.has("README.txt")) {
		fs.removeSync(readmePath);
	}
}

function pruneDirectory(currentDir, ltModulesDir, writtenOutputs) {
	for (const entry of fs.readdirSync(currentDir)) {
		const fullPath = path.join(currentDir, entry);
		const rel = path.relative(ltModulesDir, fullPath).replace(/\\/g, "/");
		const stat = fs.statSync(fullPath);

		if (stat.isDirectory()) {
			pruneDirectory(fullPath, ltModulesDir, writtenOutputs);
			if (fs.existsSync(fullPath) && fs.readdirSync(fullPath).length === 0) {
				fs.removeSync(fullPath);
			}
		} else if (!writtenOutputs.has(rel)) {
			fs.removeSync(fullPath);
		}
	}
}

function getIndividualPath(modName, type) {
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

module.exports = {
	rebuildBundle,
	generateFullApi,
	getModuleExportMap,
};
