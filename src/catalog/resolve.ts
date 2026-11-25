import { getModuleRegistry, getModuleData, getDatabase, isPublicModule } from "./database";

function getModuleDependencies(modName: string): string[] {
	const modData = getModuleData(modName);
	if (!modData) return [];
	if (Array.isArray(modData.dependencies)) return modData.dependencies;
	return [];
}

export function resolveDependencies(moduleNames: string[]) {
	const registry = getModuleRegistry();
	const resolved = new Set();
	const visiting = new Set();
	const sequence: string[] = [];
	const graph: Record<string, string[]> = Object.create(null);

	function visit(modName: string) {
		if (resolved.has(modName)) return;
		if (visiting.has(modName)) {
			throw new Error(`Circular dependency: ${[...visiting, modName].join(" -> ")}`);
		}

		visiting.add(modName);

		if (!Object.hasOwn(registry, modName)) {
			throw new Error(`Unknown LTBridge module: ${modName}`);
		}

		const deps = getModuleDependencies(modName);
		graph[modName] = deps;
		for (const dep of deps) {
			visit(dep);
		}

		visiting.delete(modName);
		resolved.add(modName);
		sequence.push(modName);
	}

	for (const name of moduleNames) {
		visit(name);
	}

	return { sequence, graph };
}

export function resolveWildcardModules(moduleName: string, registry: Record<string, string>) {
	if (!moduleName.endsWith("*")) {
		const single = resolveModuleName(moduleName, registry);
		return single ? [single] : [];
	}

	const prefix = moduleName.replace(/\\/g, "/").replace(/^@/, "").replace(/\*$/, "").toLowerCase();
	const matches = [];
	for (const key of Object.keys(registry)) {
		const normalizedKey = key.replace(/^@/, "").toLowerCase();
		if (normalizedKey.startsWith(prefix) && isPublicModule(key)) matches.push(key);
	}
	return matches;
}

export function resolveModuleName(moduleName: string, registry: Record<string, string>) {
	if (Object.hasOwn(registry, moduleName)) return moduleName;
	const normalizedInput = moduleName.replace(/\\/g, "/").replace(/^@/, "").toLowerCase();

	const matches = [];
	for (const key of Object.keys(registry)) {
		const normalizedKey = key.replace(/^@/, "").toLowerCase();
		if (normalizedKey === normalizedInput) return key;

		const parts = key.split("/");
		const lastPart = parts[parts.length - 1].toLowerCase();
		if (lastPart === normalizedInput) {
			matches.push(key);
		}
	}

	if (matches.length === 1) return matches[0];
	if (matches.length > 1) {
		throw new Error("Ambiguous module name '" + moduleName + "'. Matches: " + matches.join(", "));
	}

	// Try export map if folder name doesn't match
	const { publicExports } = getDatabase();
	const cleanName = moduleName.replace(/^LT\./, "");
	if (Object.hasOwn(publicExports, cleanName)) {
		const candidates = publicExports[cleanName];
		if (candidates.length === 1) return candidates[0];

		throw new Error("Ambiguous module name '" + moduleName + "'. Matches: " + candidates.join(", "));
	}

	return null;
}
