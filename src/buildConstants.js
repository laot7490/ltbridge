const VERSION_RE = /__LT_VERSION\s*=\s*'[^']*'/g;
const DEBUG_RE = /__LT_DISABLE_DEBUG\s*=\s*(true|false)/g;

function applyBuildConstants(source, { version, disableDebug } = {}) {
	if (!source) return source;
	let out = source;
	if (version) {
		out = out.replace(VERSION_RE, `__LT_VERSION = '${version}'`);
	}
	if (disableDebug !== undefined) {
		out = out.replace(DEBUG_RE, `__LT_DISABLE_DEBUG = ${disableDebug ? "true" : "false"}`);
	}
	return out;
}

module.exports = { applyBuildConstants };
