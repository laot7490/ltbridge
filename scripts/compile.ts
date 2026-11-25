import { publicExportNames } from "../src/catalog/exports";
import { extractStubs, extractEmmyClasses } from "../src/catalog/stubs";
import fs from "node:fs";
import path from "node:path";
import { version } from "../package.json";
import { applyBuildConstants } from "../src/lua/constants";
import { transformLtassertStatements } from "../src/lua/transform";
import { analyzeModuleDependencies } from "../src/catalog/analyze";
import { stripLuaComments } from "../src/lua/source";
import { SIDES, type ModuleData, type ModuleDatabase, type ModuleSource, type Stub, type Side } from "../src/catalog/database";

const modulesDir = path.join(__dirname, "..", "modules");
const distDir = path.join(__dirname, "..", "dist");

function addExport(index: Record<string, string[]>, name: string, moduleId: string) {
	const candidates = index[name] ??= [];
	if (!candidates.includes(moduleId)) candidates.push(moduleId);
}

function compile() {
	if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });

	const db: ModuleDatabase & { exportMap: Record<string, string[]> } = {
		version: version,
		modules: Object.create(null),
		exportMap: Object.create(null),
		publicExports: Object.create(null),
		registry: Object.create(null),
	};

	function scan(currentPath: string) {
		if (!fs.existsSync(currentPath)) return;
		const items = fs.readdirSync(currentPath);

		const isModule = items.some((i) => i === "client.lua" || i === "server.lua" || i === "shared.lua" || i === "module.json");

		if (isModule) {
			const relative = path.relative(modulesDir, currentPath);
			let name = relative.replace(/\\/g, "/");
			if (name.endsWith("/__init__")) name = name.substring(0, name.length - 9);
			const cleanName = name
				.split("/")
				.filter((p) => !p.startsWith("#"))
				.join("/");

			const nsParts = path.normalize(currentPath).split(path.sep);
			let ns = null;
			for (const part of nsParts) if (part.startsWith("@")) ns = part.substring(1);

			const modData: { ns: string | null; meta: ModuleData["meta"]; files: Partial<Record<Side, ModuleSource>> } = { ns, meta: {}, files: {} };

			const jsonPath = path.join(currentPath, "module.json");
			if (fs.existsSync(jsonPath)) {
				try {
					const metadata = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
					if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) throw new Error("Expected an object");
					delete metadata.dependencies;
					modData.meta = metadata;
				} catch (error) {
					throw new Error(`Invalid metadata at ${jsonPath}: ${error instanceof Error ? error.message : error}`);
				}
			}

			SIDES.forEach((ctx) => {
				const fPath = path.join(currentPath, `${ctx}.lua`);
				if (fs.existsSync(fPath)) {
					const rawCode = fs.readFileSync(fPath, "utf8");
					const stubs = extractStubs(rawCode, ns, ctx);
					const types = extractEmmyClasses(rawCode);
					let cleanCode = stripLuaComments(rawCode);
					cleanCode = applyBuildConstants(cleanCode, { version: version });
					cleanCode = transformLtassertStatements(cleanCode);
					modData.files[ctx] = { code: cleanCode, stubs: stubs, types: types };
				}
			});

			if (Object.hasOwn(db.modules, cleanName)) throw new Error(`Duplicate module ID ${cleanName} at ${currentPath}`);
			db.modules[cleanName] = {
				ns: modData.ns,
				meta: modData.meta,
				shared: modData.files.shared ?? null,
				client: modData.files.client ?? null,
				server: modData.files.server ?? null,
			};
			db.registry[cleanName] = relative.replace(/\\/g, "/");
		} else {
			for (const item of items) {
				if (item === "node_modules" || item === ".git" || item === "ltbridge") continue;
				const fullPath = path.join(currentPath, item);
				if (fs.statSync(fullPath).isDirectory()) scan(fullPath);
			}
		}
	}

	console.log("[LTBridge] Compiling modules Ahead-Of-Time...");
	scan(modulesDir);

	for (const [modName, modData] of Object.entries(db.modules)) {
		const processStubs = (stubs: Stub[]) => {
			if (!stubs) return;
			for (const stub of stubs) {
				const formsToExport = publicExportNames(stub.funcName, modData.ns, stub.metadata);
				if (!stub.metadata.internal && !modData.meta.internal) {
					for (const form of formsToExport) addExport(db.publicExports, form, modName);
				}
				formsToExport.push(stub.funcName);
				if (stub.metadata.export) formsToExport.push(stub.metadata.export);

				for (const form of formsToExport) addExport(db.exportMap, form, modName);
			}
		};
		if (modData.shared) processStubs(modData.shared.stubs);
		if (modData.client) processStubs(modData.client.stubs);
		if (modData.server) processStubs(modData.server.stubs);
	}

	for (const [modName, modData] of Object.entries(db.modules)) {
		const deps = analyzeModuleDependencies(modName, db);

		modData.dependencies = deps;

	}

	fs.copyFileSync(path.join(__dirname, "..", "THIRD_PARTY_NOTICES.txt"), path.join(distDir, "THIRD_PARTY_NOTICES.txt"));
	const outPath = path.join(distDir, "modules.dat");
	const { exportMap: _implementationNames, ...catalog } = db;
	fs.writeFileSync(outPath, JSON.stringify(catalog));
	console.log(`[LTBridge] Compiled ${Object.keys(db.modules).length} modules to ${outPath}`);
}

compile();
