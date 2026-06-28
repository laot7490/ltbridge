const { getModuleRegistry, getModuleData } = require("./registry");

function getModuleDependencies(modName) {
	const modData = getModuleData(modName);
	if (!modData) return [];
	if (Array.isArray(modData.dependencies)) return modData.dependencies;
	if (modData.meta && Array.isArray(modData.meta.dependencies)) return modData.meta.dependencies;
	return [];
}

function resolveDependencies(moduleNames, exportMap) {
	const registry = getModuleRegistry();
	const resolved = new Set();
	const visiting = new Set();
	const sequence = [];
	const graph = {};

	function visit(modName) {
		if (resolved.has(modName)) return;
		if (visiting.has(modName)) {
			console.log(`\n\x1b[33m! Circular dependency detected involving '${modName}'.\x1b[0m`);
			return;
		}

		visiting.add(modName);

		if (!registry[modName]) {
			console.log(`\x1b[31m✖ Trying to resolve '${modName}' but it does not exist in LTBridge.\x1b[0m`);
			visiting.delete(modName);
			return;
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

module.exports = {
	resolveDependencies,
	getModuleDependencies,
};
