import path from "node:path";
import { getDatabase, type ModuleSource } from "../catalog/database";
import { writeIfChanged } from "../project/config";

export function generateFullApi(targetDir: string) {
	const db = getDatabase();
	const apiStubs: string[] = [];
	const requiredTables = new Set();
	const typeMap = new Map<string, string>();

	for (const modData of Object.values(db.modules)) {
		if (modData.ns) requiredTables.add(`LT.${modData.ns} = LT.${modData.ns} or {}`);

		const processTypes = (ctxData: ModuleSource | null) => {
			if (!ctxData || !ctxData.types) return;
			for (const typeEntry of ctxData.types) {
				if (typeEntry && typeEntry.className && typeEntry.code) {
					typeMap.set(typeEntry.className, typeEntry.code);
				}
			}
		};
		const processCtx = (ctxData: ModuleSource | null) => {
			if (ctxData && ctxData.stubs) {
				for (const stub of ctxData.stubs) {
					if (stub.stubCode && !stub.metadata.internal) {
						apiStubs.push(stub.stubCode);
					}
				}
			}
		};
		processTypes(modData.shared);
		processTypes(modData.client);
		processTypes(modData.server);
		processCtx(modData.shared);
		processCtx(modData.client);
		processCtx(modData.server);
	}

	const ltModulesDir = path.join(targetDir, "ltbridge");

	const apiHeader = `--- @meta\n--- LT Bridge API Reference\n--- Auto-generated stub file for IDE intellisense.\n--- Do NOT include this file in your fxmanifest.\n--- For more information: https://github.com/laot7490/ltbridge\n\n`;
	const initBlock = `LT = LT or {}\n` + Array.from(requiredTables).sort().join("\n") + "\n\n";
	const typesBlock = typeMap.size > 0 ? Array.from(typeMap.values()).join("\n\n") + "\n\n" : "";
	const apiContent = apiHeader + initBlock + typesBlock + apiStubs.join("\n\n") + "\n";

	writeIfChanged(path.join(ltModulesDir, "api.lua"), apiContent);
}

