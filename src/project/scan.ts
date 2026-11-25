import fs from "node:fs";
import path from "node:path";
import { stripLuaForScan } from "../lua/source";
import { getDatabase } from "../catalog/database";
import { pickExportModule } from "../catalog/exports";

export function isExcluded(targetDir: string, filePath: string): boolean {
	const relative = path.relative(targetDir, filePath);
	const parts = relative.split(path.sep);
	return parts.some((part) => part === "node_modules" || part === ".git") ||
		parts[0] === ".." || path.isAbsolute(relative) ||
		(parts[0] === "ltbridge" && parts.length > 1 && relative !== path.join("ltbridge", "config.json")) ||
		relative === "fxmanifest.lua" || relative === "__resource.lua";
}

export function readLuaReferences(file: string): Set<string> {
	const calls = new Set<string>();
	for (const match of stripLuaForScan(fs.readFileSync(file, "utf8")).matchAll(/(?<![\w.])LT((?:\s*\.\s*[a-zA-Z_][a-zA-Z0-9_]*)+)/g)) {
		let current = "";
		for (const part of match[1].replace(/\s/g, "").slice(1).split(".")) {
			current = current ? current + "." + part : part;
			calls.add(current);
		}
	}
	return calls;
}

export function scanLuaCalls(root: string): Set<string> {
	const calls = new Set<string>();
	function scan(dir: string) {
		for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
			const file = path.join(dir, entry.name);
			if (isExcluded(root, file)) continue;
			if (entry.isDirectory()) scan(file);
			else if (entry.isFile() && file.endsWith(".lua")) {
				for (const call of readLuaReferences(file)) calls.add(call);
			}
		}
	}
	scan(root);
	return calls;
}

export function resolveReferencedModules(foundCalls: Iterable<string>) {
	const { registry, modules, publicExports } = getDatabase();
	const validRequestedModules = new Set<string>();

	for (const call of foundCalls) {
		const pathForm = "@" + call.replace(/\./g, "/");

		// Direct module path match
		if (Object.hasOwn(registry, pathForm) && !modules[pathForm]?.meta.internal) {
			validRequestedModules.add(pathForm);
			continue;
		}

		if (Object.hasOwn(publicExports, call)) {
			const match = pickExportModule(call, publicExports[call]);
			if (match) validRequestedModules.add(match);
		}
	}
	return validRequestedModules;
}
