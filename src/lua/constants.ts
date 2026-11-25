import { stripLuaForScan } from "./source";

const BUILD_CONSTANTS = /\b__LT_VERSION\s*=\s*'[^']*'|\b__LT_DISABLE_DEBUG\s*=\s*(?:true|false)\b/g;

export function applyBuildConstants(source: string, { version, disableDebug }: { version?: string; disableDebug?: boolean } = {}) {
	if (!source.includes("__LT_")) return source;
	const visible = stripLuaForScan(source);
	return source.replace(BUILD_CONSTANTS, (match, offset: number) => {
		if (visible[offset] !== "_") return match;
		if (match.startsWith("__LT_VERSION")) return version ? `__LT_VERSION = '${version}'` : match;
		return disableDebug === undefined ? match : `__LT_DISABLE_DEBUG = ${disableDebug}`;
	});
}

