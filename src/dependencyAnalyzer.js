const { pickExportModule } = require("./resolveExport");

function analyzeModuleDependencies(modName, { exportMap, registry, modules }) {
	const modData = modules[modName];
	if (!modData) return [];

	const availableModules = Object.keys(registry);
	const dependencies = new Set();

	if (modData.meta && Array.isArray(modData.meta.dependencies)) {
		for (const dep of modData.meta.dependencies) dependencies.add(dep);
	}

	let combinedCode = "";
	["shared", "client", "server"].forEach((file) => {
		if (modData[file] && modData[file].code) {
			combinedCode += modData[file].code + "\n";
		}
	});

	function addCallDependencies(fullPath) {
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

	const ltRegex = /(?:^|[^a-zA-Z0-9_.:"'\]])(LT\.[a-zA-Z0-9_.]+)/g;
	const bareRegex = /(?:^|[^a-zA-Z0-9_.:"'\]])([A-Z][a-zA-Z0-9_]*)/g;
	let match;

	while ((match = ltRegex.exec(combinedCode)) !== null) {
		addCallDependencies(match[1].substring(3));
	}

	while ((match = bareRegex.exec(combinedCode)) !== null) {
		const bareName = match[1];
		if (exportMap && exportMap[bareName]) {
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

			if (modName !== initModName && availableModules.includes(initModName)) {
				dependencies.add(initModName);
			}
			if (modName !== parentInitModName && availableModules.includes(parentInitModName)) {
				dependencies.add(parentInitModName);
			}
		}
	}

	return Array.from(dependencies).sort();
}

module.exports = { analyzeModuleDependencies };
