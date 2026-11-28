import { color, log } from "./log";
import { version } from "../../package.json";
import { rebuildAndSaveConfig, rebuildBundle, type BuildOptions } from "../build/index";
import { resolveDependencies, resolveModuleName, resolveWildcardModules } from "../catalog/resolve";
import { getModuleRegistry, isPublicModule } from "../catalog/database";
import { scanLuaCalls, resolveReferencedModules } from "../project/scan";
import { watchProject as watch } from "../project/watch";
import { generateFullApi } from "../build/api";
import { readProjectConfig, saveConfig, withProjectWrite } from "../project/config";

function resolveModuleRequest(targetDir: string, moduleName: string) {
	const config = readProjectConfig(targetDir);
	const resolvedNames = resolveWildcardModules(moduleName, getModuleRegistry());

	if (resolvedNames.length === 0) {
		log(`✖ No modules found matching '${moduleName}'.`, "red");
		throw new Error("Module command failed.");
	}
	return { config, resolvedNames, wildcard: moduleName.endsWith("*") };
}

export function addModule(targetDir: string, moduleName: string) {
	const { config, resolvedNames, wildcard } = resolveModuleRequest(targetDir, moduleName);

	let addedCount = 0;
	let internalBlocked = false;

	for (const resolvedName of resolvedNames) {
		if (resolvedName === "__init__") continue;

		if (!isPublicModule(resolvedName)) {
			if (!wildcard) {
				log(`✖ Cannot manually add internal ghost module '${resolvedName}'.`, "red");
				log(`ℹ Ghost modules are active and managed purely as auto-dependencies behind the scenes.`, "gray");
				internalBlocked = true;
			}
			continue;
		}

		if (config.modules.includes(resolvedName)) {
			if (!wildcard) {
				log(`ℹ Module '${resolvedName}' is already added.`, "gray");
			}
			continue;
		}

		config.modules.push(resolvedName);
		log(`✓ Added module '${resolvedName}'.`, "green");
		addedCount++;
	}

	if (addedCount > 0) {
		rebuildAndSaveConfig(targetDir, config);
	} else if (wildcard) {
		log(`ℹ All matching modules are already added.`, "gray");
	} else if (internalBlocked) {
		throw new Error("Module command failed.");
	}
}

export function removeModule(targetDir: string, moduleName: string) {
	const { config, resolvedNames, wildcard } = resolveModuleRequest(targetDir, moduleName);

	let removedCount = 0;

	for (const resolvedName of resolvedNames) {
		if (!config.modules.includes(resolvedName)) {
			if (!wildcard) {
				log(`ℹ Module '${resolvedName}' is not currently added.`, "gray");
			}
			continue;
		}

		config.modules = config.modules.filter((m) => m !== resolvedName);
		log(`- Removed module '${resolvedName}'.`, "yellow");
		removedCount++;
	}

	if (removedCount > 0) {
		rebuildAndSaveConfig(targetDir, config);
	} else if (wildcard) {
		log(`ℹ No matching modules were currently added.`, "gray");
	}
}

export function watchProject(targetDir: string, options: BuildOptions) {
	return watch(targetDir, (config) => rebuildBundle(targetDir, config, options));
}

export function buildProject(targetDir: string, options: BuildOptions = {}) {
	const config = readProjectConfig(targetDir);
	log(`\n${color(`⚡ ltbridge v${version}`, "cyan")} ${color(`building for production...`, "green")}`);
	const previousVersion = config.version;
	rebuildBundle(targetDir, config, options);
	if (config.version !== previousVersion) saveConfig(targetDir, config);
}

export function pruneModules(targetDir: string) {
	const config = readProjectConfig(targetDir);
	log(`ℹ Scanning project for unused LT modules...`, "gray");

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
		log(`✓ Pruned ${removed.length} unused modules: ${removed.join(", ")}`, "green");
		config.modules = toKeep;
	} else {
		log(`ℹ No unused modules found. Everything is tightly integrated!`, "gray");
	}

	rebuildAndSaveConfig(targetDir, config);
}

export function explainModule(targetDir: string, moduleName: string) {
	const registry = getModuleRegistry();
	const resolvedName = resolveModuleName(moduleName, registry);

	if (!resolvedName) {
		log(`✖ Module '${moduleName}' does not exist in the repository.`, "red");
		throw new Error("Module command failed.");
	}

	const config = readProjectConfig(targetDir);
	const installed = new Set(config.modules);
	const { graph } = resolveDependencies(config.modules);

	const isManual = installed.has(resolvedName);
	const parents = Object.keys(graph).filter((parent) => graph[parent].includes(resolvedName));
	const isDep = parents.length > 0;

	log(`\n${color(`ℹ Why is '${resolvedName}' included in your project?`, "heading")}`);

	if (resolvedName === "__init__") {
		log("  Included automatically in every LTBridge build.");
		return;
	}
	if (!isManual && !isDep) {
		log(`  ${color(`○ This module is NOT currently included in your project build.`, "gray")}\n`);
		return;
	}

	if (isManual) {
		log(`  ${color(`✔ You explicitly added it to your ltbridge/config.json`, "green")}`);
	}

	if (isDep) {
		log(`  ${color(`⚙ It is automatically included as a dependency for the following modules:`, "yellow")}`);
		for (const p of parents) {
			log(`    - ${p}`);
		}
	}
	log("");
}

export function regenerateApi(targetDir: string) {
	log(`\n${color(`⚡ ltbridge`, "cyan")} ${color(`Regenerating API stubs...`, "green")}`);
	withProjectWrite(targetDir, () => generateFullApi(targetDir));
	log(`${color(`✓ API reference successfully updated.`, "green")}\n`);
}
