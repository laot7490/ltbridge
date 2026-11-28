import path from "node:path";
import { getDatabase, SIDES } from "../catalog/database";
import { writeIfChanged } from "../project/config";

export function generateFullApi(targetDir: string) {
	const db = getDatabase();
	const apiStubs: string[] = [];
	const requiredTables = new Set();
	const classes = new Map<string, string>();

	for (const module of Object.values(db.modules)) {
		if (module.ns) requiredTables.add(`LT.${module.ns} = LT.${module.ns} or {}`);

		for (const side of SIDES) {
			const source = module[side];
			for (const entry of source?.types || []) {
				if (entry?.className && entry.code) classes.set(entry.className, entry.code);
			}
			for (const stub of source?.stubs || []) {
				if (stub.stubCode && !stub.metadata.internal) apiStubs.push(stub.stubCode);
			}
		}
	}

	const ltModulesDir = path.join(targetDir, "ltbridge");

	const apiHeader = `--- @meta\n--- LT Bridge API Reference\n--- Auto-generated stub file for IDE intellisense.\n--- Do NOT include this file in your fxmanifest.\n--- For more information: https://github.com/laot7490/ltbridge\n\n`;
	const initBlock = `LT = LT or {}\n` + Array.from(requiredTables).sort().join("\n") + "\n\n";
	const typesBlock = classes.size > 0 ? Array.from(classes.values()).join("\n\n") + "\n\n" : "";
	const apiContent = apiHeader + initBlock + typesBlock + apiStubs.join("\n\n") + "\n";

	writeIfChanged(path.join(ltModulesDir, "api.lua"), apiContent);
}
