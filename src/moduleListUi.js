const { getModuleRegistry, getModuleData } = require("./registry");
const { resolveDependencies } = require("./moduleResolver");
const { getModuleExportMap } = require("./bundler");

function getVisibleModules() {
	const registry = getModuleRegistry();
	return Object.keys(registry).filter((m) => {
		if (m === "__init__") return false;
		const modData = getModuleData(m);
		if (modData && modData.meta && modData.meta.internal === true) return false;
		return true;
	});
}

function buildModuleGroups(allModules, registry) {
	const groups = {};

	for (const mod of allModules) {
		const registryPath = registry[mod];
		const groupTokens = [];

		if (registryPath) {
			const parts = registryPath.split("/");
			for (let i = 0; i < parts.length - 1; i++) {
				let token = parts[i];
				if (token.startsWith("@") || token.startsWith("#")) {
					token = token.substring(1);
				}
				groupTokens.push(token);
			}
		}

		const group = groupTokens.length > 0 ? groupTokens.join(" / ") : "Uncategorized";
		const name = mod.split("/").pop();

		if (!groups[group]) groups[group] = [];
		groups[group].push({ mod, name });
	}

	return groups;
}

function getDependencySets(configModules) {
	const depsSet = new Set();

	if (configModules && configModules.length > 0) {
		const { graph } = resolveDependencies(configModules, getModuleExportMap());
		for (const deps of Object.values(graph)) {
			for (const d of deps) {
				depsSet.add(d);
			}
		}
	}

	return depsSet;
}

function getFilteredSortedMods(modsInGroup, group) {
	const lastPart = group.split(" / ").pop();
	const initModName = "@" + lastPart;
	const filteredMods = modsInGroup.length > 1 ? modsInGroup.filter((m) => m.mod !== initModName) : modsInGroup;
	return filteredMods.sort((a, b) => a.name.localeCompare(b.name));
}

module.exports = {
	getVisibleModules,
	buildModuleGroups,
	getDependencySets,
	getFilteredSortedMods,
};
