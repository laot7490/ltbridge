import { getModuleData, SIDES, type StubMetadata } from "./database";

export function publicExportNames(functionName: string, namespace: string | null, metadata: StubMetadata): string[] {
	const prefix = namespace ? namespace + "." : "";
	const exported = metadata.export ?? functionName;
	const global = metadata.global === true ? exported : metadata.global;
	const names = metadata.export || !global ? [prefix + exported] : [];
	if (global) names.push(global);
	for (const alias of metadata.alias ?? []) names.push(prefix + alias);
	return [...new Set(names)];
}

function moduleHasGlobalStub(modName: string, lookup = getModuleData) {
	const modData = lookup(modName);
	if (!modData) return false;

	return SIDES.some((side) => modData[side]?.stubs.some((stub) => stub.metadata.global));
}

export function pickExportModule(call: string, candidates: string[] | undefined, lookup = getModuleData) {
	if (!candidates || candidates.length === 0) return null;
	if (candidates.length === 1) return candidates[0];

	if (call.includes(".")) {
		const ns = call.split(".")[0].toLowerCase();
		const bestMatch = candidates.find((c) => c.toLowerCase().includes(ns));
		if (bestMatch) return bestMatch;
	}

	const globalMatch = candidates.find((c) => moduleHasGlobalStub(c, lookup));
	return globalMatch || candidates[0];
}
