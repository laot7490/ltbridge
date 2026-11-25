import { version } from "../../package.json";
import fs from "node:fs";
import path from "node:path";

export const SIDES = ["shared", "client", "server"] as const;
export type Side = (typeof SIDES)[number];
export interface StubMetadata {
  export?: string;
  global?: true | string;
  internal?: boolean;
  alias?: string[];
}
export interface Stub { funcName: string; metadata: StubMetadata; stubCode: string }
export interface LuaClass { className: string; code: string }
export interface ModuleSource { code: string; stubs: Stub[]; types: LuaClass[] }
export type ModuleData = Record<Side, ModuleSource | null> & {
  ns: string | null;
  meta: { internal?: boolean; [key: string]: unknown };
  dependencies?: string[];
};
export interface ModuleDatabase {
  version: string;
  modules: Record<string, ModuleData>;
  registry: Record<string, string>;
  publicExports: Record<string, string[]>;
}

let _dbCache: ModuleDatabase | undefined;

export function getDatabase(): ModuleDatabase {
	if (_dbCache) return _dbCache;
	const dbPath = path.join(__dirname, "modules.dat");
	if (!fs.existsSync(dbPath)) throw new Error("LTBridge catalog missing. Reinstall LTBridge or run npm run build.");
	const database = JSON.parse(fs.readFileSync(dbPath, "utf8"));
	if (!database || typeof database.version !== "string" || !database.modules || !database.registry || !database.publicExports) {
		throw new Error("Invalid LTBridge module database");
	}
	if (database.version !== version) throw new Error("LTBridge catalog version mismatch. Reinstall LTBridge or run npm run build.");
	_dbCache = database;
	return database;
}

export function getModuleRegistry() {
	return getDatabase().registry;
}

export function getModuleData(modName: string): ModuleData | undefined {
	const { modules } = getDatabase();
	return Object.hasOwn(modules, modName) ? modules[modName] : undefined;
}


export function isPublicModule(id: string): boolean {
	const module = getModuleData(id);
	return id !== '__init__' && module !== undefined && !module.meta.internal;
}
