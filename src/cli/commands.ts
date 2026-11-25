import type { BuildOptions } from "../build/index";
import fs from "node:fs";
import path from "node:path";
import { version } from "../../package.json";
import { rebuildBundle } from "../build/index";
import { resolveDependencies, resolveModuleName, resolveWildcardModules } from "../catalog/resolve";
import { getModuleRegistry, isPublicModule } from "../catalog/database";
import { scanLuaCalls, resolveReferencedModules } from "../project/scan";
import { watchProject as watch } from "../project/watch";
import prompts from "prompts";

import { CONFIG_FILE, readProjectConfig, saveConfig, withProjectWrite, writeIfChanged } from "../project/config";
const LUA_IGNORE_DIR = "**/ltbridge/modules/**";

function ensureVscodeLuaIgnore(targetDir: string) {
	const vscodeDir = path.join(targetDir, ".vscode");
	const settingsPath = path.join(vscodeDir, "settings.json");
	let settings: Record<string, unknown> = {};
	if (fs.existsSync(settingsPath)) {
		try {
			settings = JSON.parse(fs.readFileSync(settingsPath, "utf-8"));
		} catch {
			console.log(`\x1b[33m! Could not parse .vscode/settings.json — skipping Lua ignoreDir update.\x1b[0m`);
			return;
		}
	}
	const key = "Lua.workspace.ignoreDir";
	const existing = settings[key];
	if (Array.isArray(existing)) {
		if (existing.includes(LUA_IGNORE_DIR)) {
			console.log(`\x1b[90mℹ VS Code Lua ignoreDir already includes ltbridge/modules\x1b[0m`);
			return;
		}
		settings[key] = [...existing, LUA_IGNORE_DIR];
	} else if (typeof existing === "string") {
		if (existing === LUA_IGNORE_DIR) {
			console.log(`\x1b[90mℹ VS Code Lua ignoreDir already includes ltbridge/modules\x1b[0m`);
			return;
		}
		settings[key] = [existing, LUA_IGNORE_DIR];
	} else {
		settings[key] = [LUA_IGNORE_DIR];
	}
	writeIfChanged(settingsPath, JSON.stringify(settings, null, "\t") + "\n");
	console.log(`\x1b[32m✓ Updated .vscode/settings.json (Lua.workspace.ignoreDir)\x1b[0m`);
}

export async function initProject(targetDir: string) {
	const configPath = path.join(targetDir, CONFIG_FILE);
	const originalConfig = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : undefined;

	if (originalConfig !== undefined) {
		const overwrite = await prompts({
			type: "confirm",
			name: "value",
			message: "LTBridge is already initialized. Do you want to overwrite the configuration?",
			initial: false,
		});
		if (!overwrite.value) {
			console.log(`\x1b[33m! Initialization cancelled.\x1b[0m`);
			return;
		}
	}

	console.log(`\n\x1b[36m⚡ ltbridge v${version}\x1b[0m \x1b[32mInitializing project...\x1b[0m\n`);

	const response = await prompts([
		{
			type: "select",
			name: "buildMode",
			message: "Build Output Mode:",
			choices: [
				{ title: "Individual (Separate files per module)", value: false },
				{ title: "Bundle (Combine all into 3 files)", value: true },
			],
			initial: 0,
		},
		{
			type: "select",
			name: "minify",
			message: "Bundled code minification:",
			choices: [
				{ title: "Enabled (Compact production code)", value: true },
				{ title: "Disabled (Readable development code)", value: false },
			],
			initial: 1,
		},
		{
			type: "select",
			name: "debug",
			message: "Runtime debug mode:",
			choices: [
				{ title: "Disabled (Recommended for production)", value: false },
				{ title: "Enabled (Detailed logs and helper outputs)", value: true },
			],
			initial: 0,
		},
		{
			type: "confirm",
			name: "vscodeIgnore",
			message: "Add Lua.workspace.ignoreDir for ltbridge/modules to .vscode/settings.json?",
			initial: false,
		},
	]);

	if ([response.buildMode, response.minify, response.debug, response.vscodeIgnore].some((value) => typeof value !== "boolean")) {
		console.log(`\x1b[33m! Initialization cancelled.\x1b[0m`);
		return;
	}

	const doBundle = response.buildMode === true;
	const doMinify = response.minify === true;
	const doDebug = response.debug === true;

	const initialConfig = {
		bundle: doBundle,
		debug: doDebug,
		minify: doMinify,
		modules: [],
	};
	withProjectWrite(targetDir, () => {
		const current = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : undefined;
		if (current !== originalConfig) throw new Error("LTBridge config changed during setup. Run init again.");
		rebuildBundle(targetDir, initialConfig);
		saveConfig(targetDir, initialConfig);
	});
	console.log(`\n\x1b[32m✓ Created configuration: ${CONFIG_FILE}\x1b[0m`);
	console.log(`\x1b[90mℹ Build Mode: ${doBundle ? "bundle" : "individual"}\x1b[0m`);
	console.log(`\x1b[90mℹ Minify: ${doMinify ? "enabled" : "disabled"}\x1b[0m`);
	console.log(`\x1b[90mℹ Debug: ${doDebug ? "enabled" : "disabled"}\x1b[0m\n`);

	if (response.vscodeIgnore) {
		ensureVscodeLuaIgnore(targetDir);
	}
}

export function addModule(targetDir: string, moduleName: string) {
	const config = readProjectConfig(targetDir);
	const registry = getModuleRegistry();
	const resolvedNames = resolveWildcardModules(moduleName, registry);

	if (resolvedNames.length === 0) {
		console.log(`\x1b[31m✖ No modules found matching '${moduleName}'.\x1b[0m`);
		throw new Error("Module command failed.");
	}

	let addedCount = 0;
	let internalBlocked = false;

	for (const resolvedName of resolvedNames) {
		if (resolvedName === "__init__") continue;

		if (!isPublicModule(resolvedName)) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[31m✖ Cannot manually add internal ghost module '${resolvedName}'.\x1b[0m`);
				console.log(`\x1b[90mℹ Ghost modules are active and managed purely as auto-dependencies behind the scenes.\x1b[0m`);
				internalBlocked = true;
			}
			continue;
		}

		if (config.modules.includes(resolvedName)) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[90mℹ Module '${resolvedName}' is already added.\x1b[0m`);
			}
			continue;
		}

		config.modules.push(resolvedName);
		console.log(`\x1b[32m✓ Added module '${resolvedName}'.\x1b[0m`);
		addedCount++;
	}

	if (addedCount > 0) {
		rebuildBundle(targetDir, config);
		saveConfig(targetDir, config);
	} else if (moduleName.endsWith("*")) {
		console.log(`\x1b[90mℹ All matching modules are already added.\x1b[0m`);
	} else if (internalBlocked) {
		throw new Error("Module command failed.");
	}
}

export function removeModule(targetDir: string, moduleName: string) {
	const config = readProjectConfig(targetDir);
	const registry = getModuleRegistry();
	const resolvedNames = resolveWildcardModules(moduleName, registry);

	if (resolvedNames.length === 0) {
		console.log(`\x1b[31m✖ No modules found matching '${moduleName}'.\x1b[0m`);
		throw new Error("Module command failed.");
	}

	let removedCount = 0;

	for (const resolvedName of resolvedNames) {
		if (!config.modules.includes(resolvedName)) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[90mℹ Module '${resolvedName}' is not currently added.\x1b[0m`);
			}
			continue;
		}

		config.modules = config.modules.filter((m) => m !== resolvedName);
		console.log(`\x1b[33m- Removed module '${resolvedName}'.\x1b[0m`);
		removedCount++;
	}

	if (removedCount > 0) {
		rebuildBundle(targetDir, config);
		saveConfig(targetDir, config);
	} else if (moduleName.endsWith("*")) {
		console.log(`\x1b[90mℹ No matching modules were currently added.\x1b[0m`);
	}
}

export function watchProject(targetDir: string, options: BuildOptions) {
	return watch(targetDir, (config) => rebuildBundle(targetDir, config, options));
}

export function refreshModules(targetDir: string, options: BuildOptions = {}) {
	const config = readProjectConfig(targetDir);
	console.log(`\n\x1b[36m⚡ ltbridge v${version}\x1b[0m \x1b[32mbuilding for production...\x1b[0m`);
	const previousVersion = config.version;
	rebuildBundle(targetDir, config, options);
	if (config.version !== previousVersion) saveConfig(targetDir, config);
}

export function pruneModules(targetDir: string) {
	const config = readProjectConfig(targetDir);
	console.log(`\x1b[90mℹ Scanning project for unused LT modules...\x1b[0m`);

	const foundCalls = scanLuaCalls(targetDir);
	const validRequestedModules = resolveReferencedModules(foundCalls);

	const toKeep = [];
	const removed = [];

	for (const m of config.modules) {
		if (validRequestedModules.has(m)) {
			toKeep.push(m);
		} else {
			removed.push(m);
		}
	}

	if (removed.length > 0) {
		console.log(`\x1b[32m✓ Pruned ${removed.length} unused modules: ${removed.join(", ")}\x1b[0m`);
		config.modules = toKeep;
	} else {
		console.log(`\x1b[90mℹ No unused modules found. Everything is tightly integrated!\x1b[0m`);
	}

	rebuildBundle(targetDir, config);
	saveConfig(targetDir, config);
}

export function explainModule(targetDir: string, moduleName: string) {
	const registry = getModuleRegistry();
	const resolvedName = resolveModuleName(moduleName, registry);

	if (!resolvedName) {
		console.log(`\x1b[31m✖ Module '${moduleName}' does not exist in the repository.\x1b[0m`);
		throw new Error("Module command failed.");
	}

	const config = readProjectConfig(targetDir);
	const installed = new Set(config.modules || []);
	const { graph } = resolveDependencies(config.modules || []);

	const dependentOf: Record<string, string[]> = {};
	for (const [parentModule, deps] of Object.entries(graph)) {
		for (const d of deps) {
			if (!dependentOf[d]) dependentOf[d] = [];
			if (!dependentOf[d].includes(parentModule)) dependentOf[d].push(parentModule);
		}
	}

	const isManual = installed.has(resolvedName);
	const parents = dependentOf[resolvedName] || [];
	const isDep = parents.length > 0;

	console.log(`\n\x1b[1m\x1b[36mℹ Why is '${resolvedName}' included in your project?\x1b[0m`);

	if (resolvedName === "__init__") {
		console.log("  Included automatically in every LTBridge build.");
		return;
	}
	if (!isManual && !isDep) {
		console.log(`  \x1b[90m○ This module is NOT currently included in your project build.\x1b[0m\n`);
		return;
	}

	if (isManual) {
		console.log(`  \x1b[32m✔ You explicitly added it to your ltbridge/config.json\x1b[0m`);
	}

	if (isDep) {
		console.log(`  \x1b[33m⚙ It is automatically included as a dependency for the following modules:\x1b[0m`);
		for (const p of parents) {
			console.log(`    - ${p}`);
		}
	}
	console.log("");
}
