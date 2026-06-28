const crypto = require("crypto");
const fs = require("fs-extra");
const path = require("path");

const BUILD_STATE_FILE = path.join("ltbridge", ".build-state.json");

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
		minify: config.minify !== false,
		buildAsBundle: config.buildAsBundle === true,
		debug: config.debug === true,
		scanSignature: computeScanSignature(foundCalls),
	};
	return hashString(JSON.stringify(payload));
}

function getBuildStatePath(targetDir) {
	return path.join(targetDir, BUILD_STATE_FILE);
}

function loadBuildState(targetDir) {
	const statePath = getBuildStatePath(targetDir);
	if (!fs.existsSync(statePath)) return null;
	try {
		return JSON.parse(fs.readFileSync(statePath, "utf-8"));
	} catch {
		return null;
	}
}

function pad(value) {
	return String(value).padStart(2, "0");
}

function formatLocalTimestamp(date = new Date()) {
	const offset =
		new Intl.DateTimeFormat(undefined, { timeZoneName: "shortOffset" })
			.formatToParts(date)
			.find((part) => part.type === "timeZoneName")?.value || "";
	return `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}${offset ? " " + offset : ""}`;
}

function saveBuildState(targetDir, fingerprint) {
	const statePath = getBuildStatePath(targetDir);
	fs.ensureDirSync(path.dirname(statePath));
	fs.writeFileSync(statePath, JSON.stringify({ fingerprint, updatedAt: formatLocalTimestamp() }, null, 2));
}

module.exports = {
	computeBuildFingerprint,
	computeScanSignature,
	loadBuildState,
	saveBuildState,
};
