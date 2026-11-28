import { stripLuaSource } from "../lua/source";
import { pickExportModule } from "./exports";
import { SIDES, type ModuleDatabase } from "./database";

export function analyzeModuleDependencies(
	modName: string,
	{ exportMap, registry, modules }: ModuleDatabase & { exportMap: Record<string, string[]> },
) {
	const modData = modules[modName];
	if (!modData) return [];

	const hasModule = (name: string) => Object.hasOwn(registry, name);
	const lookup = (name: string) => modules[name];
	const dependencies = new Set<string>();

	let moduleCode = "";
	for (const side of SIDES) moduleCode += (modData[side]?.code ?? "") + "\n";

	moduleCode = stripLuaSource(moduleCode, "mask-for-scan");

	function addCallDependencies(fullPath: string) {
		const parts = fullPath.split(".");
		let current = "";

		for (const part of parts) {
			current = current ? current + "." + part : part;
			const pathForm = "@" + current.replace(/\./g, "/");
			const rawPathForm = current.replace(/\./g, "/");

			if (hasModule(pathForm) && pathForm !== modName) {
				dependencies.add(pathForm);
			} else if (hasModule(rawPathForm) && rawPathForm !== modName) {
				dependencies.add(rawPathForm);
			} else if (hasModule(current) && current !== modName) {
				dependencies.add(current);
			}

			if (exportMap[current]) {
				const finalMatch = pickExportModule(current, exportMap[current], lookup);
				if (finalMatch && finalMatch !== modName) dependencies.add(finalMatch);
			}
		}
	}

	const ltRegex = /(?:^|[^a-zA-Z0-9_.:"'\]])(LT\.[a-zA-Z0-9_.]+)/g;
	const bareRegex = /(?:^|[^a-zA-Z0-9_.:"'\]])([A-Z][a-zA-Z0-9_]*)/g;
	let match;

	while ((match = ltRegex.exec(moduleCode)) !== null) {
		addCallDependencies(match[1].substring(3));
	}

	while ((match = bareRegex.exec(moduleCode)) !== null) {
		const bareName = match[1];
		if (exportMap[bareName]) {
			addCallDependencies(bareName);
		}
	}

	const relPath = registry[modName];
	if (relPath) {
		let currentDir = relPath.replace(/\\/g, "/");
		const parts = currentDir.split("/");
		while (parts.length > 1) {
			parts.pop();
			const parentDirName = parts[parts.length - 1];
			const initModName = parentDirName;
			const parentInitModName = "@" + parentDirName;

			if (modName !== initModName && hasModule(initModName)) {
				dependencies.add(initModName);
			}
			if (modName !== parentInitModName && hasModule(parentInitModName)) {
				dependencies.add(parentInitModName);
			}
		}
	}

	return Array.from(dependencies).sort();
}
