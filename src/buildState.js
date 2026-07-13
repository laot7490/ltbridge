const crypto = require("crypto");

function hashString(str) {
	return crypto.createHash("sha256").update(str).digest("hex").substring(0, 16);
}

function computeScanSignature(foundCalls) {
	const sorted = Array.from(foundCalls).sort();
	return hashString(sorted.join("\n"));
}

function computeBuildFingerprint(config, cliVersion, foundCalls) {
	const payload = {
		cliVersion,
		modules: [...(config.modules || [])].sort(),
		minify: config.minify === true,
		bundle: config.bundle === true,
		debug: config.debug === true,
		scanSignature: computeScanSignature(foundCalls),
	};
	return hashString(JSON.stringify(payload));
}

module.exports = {
	computeBuildFingerprint,
	computeScanSignature,
};
