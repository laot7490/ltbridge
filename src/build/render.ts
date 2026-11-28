import { log } from "../cli/log";
import { formatBuildOutputs, type RenderedChunk } from "./layout";
import crypto from "node:crypto";
import { version } from "../../package.json";
import { applyBuildConstants } from "../lua/constants";
import { mapLuaCode, stripLuaSource } from "../lua/source";
import { getModuleData, SIDES, type Side, type StubMetadata } from "../catalog/database";
import type { ProjectConfig } from "../project/config";

export function renderBundle(loadSequence: string[], config: ProjectConfig) {
	const doMinify = config.minify === true;
	const buildAsIndividual = config.bundle !== true;

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
					finalContent = mapLuaCode(content, (code, offset) =>
						code.replace(/(^|\n)(?=[^\r\n]*\S)/g, (line, before, index) => (index > 0 || before || offset === 0 ? line + "\t" : line)),
					);
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
		}
		collectedSources.push(sources);
	};

	for (const modName of loadSequence) {
		processModule(modName);
	}

	const luamin = doMinify ? require("../vendor/luamin.cjs") : undefined;
	const minifySafe = (source: string, name: string): string => {
		if (!doMinify) return source;
		try {
			return luamin.Minify(source, { RenameVariables: true, RenameGlobals: false, SolveMath: false });
		} catch (e) {
			log(`! Minification failed for ${name}. Emitting unminified code. Error: ${e instanceof Error ? e.message : e}`, "yellow");
			return source;
		}
	};

	const GLOBAL_BLACKLIST = ["LT", "QBCore", "ESX", "QBX", "exports"];
	const globalsToRandomize = new Set<string>();
	const collectGlobals = (source: string) => {
		source = stripLuaSource(source, "mask-for-scan");
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
			for (const side of SIDES) if (mod[side]) collectGlobals(mod[side]);
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
		return (globalMappings[name] = `__` + h);
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
			for (const side of SIDES) mod[side] = randomizeGlobals(mod[side]);
		}
	}

	const bundleRequiredTables = {
		shared: new Set<string>(),
		client: new Set<string>(),
		server: new Set<string>(),
	};

	const rules = Object.keys(funcNamespaceMap)
		.sort((a, b) => b.length - a.length)
		.map((name) => {
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
		const identifiers = new Set(stripLuaSource(source, "mask-for-scan").match(/[a-zA-Z_][a-zA-Z0-9_]*/g));

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

			rewrites.push((code) =>
				code
					.replace(declaration, `$1${targetReplacement}$2`)
					.replace(normalize, "$1$2")
					.replace(call, (m, prefix, _func, suffix) => {
						if (prefix.trim().endsWith("function")) return m;
						return `${prefix}${targetReplacement}${suffix}`;
					}),
			);
		}

		const newSource = rewrites.length
			? mapLuaCode(source, (code) => rewrites.reduce((result, rewrite) => rewrite(result), code))
			: source;
		if (targetRequiredTables) {
			return newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		} else {
			const initStr = `LT = LT or {}\n` + Array.from(requiredTables).join("\n") + (requiredTables.size > 0 ? `\n\n` : `\n`);
			return initStr + newSource + (extraExports.length > 0 ? `\n-- Exports\n${extraExports}` : "");
		}
	};

	const chunks: RenderedChunk[] = [];
	for (const sources of collectedSources) {
		for (const side of SIDES) {
			if (!sources[side]) continue;
			const code = injectLTNamespace(sources[side], buildAsIndividual ? null : bundleRequiredTables[side]);
			const content = minifySafe(code, sources.moduleId + " " + side + ".lua");
			chunks.push({ moduleId: sources.moduleId, side, content });
		}
	}

	return formatBuildOutputs(chunks, bundleRequiredTables, buildAsIndividual);
}
