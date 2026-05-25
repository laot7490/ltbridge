const { getModuleData } = require("./registry");

function moduleHasGlobalStub(modName) {
	const modData = getModuleData(modName);
	if (!modData) return false;

	for (const ctx of ["shared", "client", "server"]) {
		if (modData[ctx] && modData[ctx].stubs) {
			if (modData[ctx].stubs.some((s) => s.metadata && s.metadata.global)) {
				return true;
			}
		}
	}
	return false;
}

function pickExportModule(call, candidates) {
	if (!candidates || candidates.length === 0) return null;
	if (candidates.length === 1) return candidates[0];

	if (call.includes(".")) {
		const ns = call.split(".")[0].toLowerCase();
		const bestMatch = candidates.find((c) => c.toLowerCase().includes(ns));
		if (bestMatch) return bestMatch;
	}

	const globalMatch = candidates.find((c) => moduleHasGlobalStub(c));
	return globalMatch || candidates[0];
}

module.exports = {
	pickExportModule,
	moduleHasGlobalStub,
};
