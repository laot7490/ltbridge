const { getModuleRegistry, getModuleData } = require("./registry");
const { pickExportModule } = require("./resolveExport");

function resolveDependencies(moduleNames, exportMap) {
	const registry = getModuleRegistry();
	const availableModules = Object.keys(registry);
	const resolved = new Set();
	const visiting = new Set();
	const sequence = [];
	const graph = {};

	function getAutoDependencies(modName, exportMap) {
		const modData = getModuleData(modName);
		if (!modData) return [];

		if (modData.meta && Array.isArray(modData.meta.dependencies)) {
			return modData.meta.dependencies;
		}

		const dependencies = new Set();
		let combinedCode = "";

		["shared", "client", "server"].forEach((file) => {
			if (modData[file] && modData[file].code) {
				combinedCode += modData[file].code + "\n";
			}
		});

		const regex = /(?:^|[^a-zA-Z0-9_.:"'\]])(LT\.[a-zA-Z0-9_.]+)/g;
		let match;
		while ((match = regex.exec(combinedCode)) !== null) {
			let fullPath = match[1].substring(3);

			const parts = fullPath.split(".");
			let current = "";

			for (const part of parts) {
				current = current ? current + "." + part : part;
				const pathForm = "@" + current.replace(/\./g, "/");
				const rawPathForm = current.replace(/\./g, "/");

				if (availableModules.includes(pathForm) && pathForm !== modName) {
					dependencies.add(pathForm);
				} else if (availableModules.includes(rawPathForm) && rawPathForm !== modName) {
					dependencies.add(rawPathForm);
				} else if (availableModules.includes(current) && current !== modName) {
					dependencies.add(current);
				}

				if (exportMap && exportMap[current]) {
					const finalMatch = pickExportModule(current, exportMap[current]);
					if (finalMatch && finalMatch !== modName) dependencies.add(finalMatch);
				}
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

				if (modName !== initModName && availableModules.includes(initModName)) {
					dependencies.add(initModName);
				}
				if (modName !== parentInitModName && availableModules.includes(parentInitModName)) {
					dependencies.add(parentInitModName);
				}
			}
		}

		return Array.from(dependencies);
	}

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

		const deps = getAutoDependencies(modName, exportMap);
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
};
