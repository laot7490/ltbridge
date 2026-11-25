import fs from 'node:fs';
import path from 'node:path';
import { randomUUID } from 'node:crypto';

export const CONFIG_FILE = path.join('ltbridge', 'config.json');

export interface ProjectConfig {
  version?: string;
  modules: string[];
  bundle?: boolean;
  debug?: boolean;
  minify?: boolean;
  [key: string]: unknown;
}

export function readProjectConfig(root: string): ProjectConfig;
export function readProjectConfig(root: string, optional: true): ProjectConfig | undefined;
export function readProjectConfig(root: string, optional = false): ProjectConfig | undefined {
  const file = path.join(root, CONFIG_FILE);
  if (optional && !fs.existsSync(file)) return undefined;
  if (!fs.existsSync(file)) throw new Error("Not an LTBridge initialized directory. Run 'ltbridge init' first.");
  const data: unknown = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid LTBridge configuration');
  const config = data as Record<string, unknown>;
  for (const key of ["bundle", "debug", "minify"]) {
    if (config[key] !== undefined && typeof config[key] !== "boolean") throw new Error("Expected boolean config field " + key);
  }
  if (config.version !== undefined && typeof config.version !== "string") throw new Error("Expected a string config version");
  const modules = config.modules === undefined ? [] : config.modules;
  if (!Array.isArray(modules) || !modules.every((name) => typeof name === 'string')) {
    throw new Error('LTBridge config modules must be an array of strings');
  }
  return { ...config, modules };
}

export function writeIfChanged(file: string, content: string): void {
  if (fs.existsSync(file) && fs.readFileSync(file, 'utf8') === content) return;
  writeFileAtomic(file, content);
}

export function writeFileAtomic(file: string, content: string): void {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.${randomUUID()}.tmp`;
  try {
    fs.writeFileSync(temporary, content, { flag: 'wx' });
    fs.renameSync(temporary, file);
  } finally {
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}

export function saveConfig(root: string, config: ProjectConfig): void {
  writeIfChanged(path.join(root, CONFIG_FILE), JSON.stringify(config, null, 2));
}


export function withProjectWrite<T>(root: string, write: () => T): T {
  const lock = path.join(root, 'ltbridge', '.write-lock');
  fs.mkdirSync(path.dirname(lock), { recursive: true });
  let fd: number;
  try {
    fd = fs.openSync(lock, 'wx');
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'EEXIST') {
      throw new Error('Another LTBridge write is in progress. If it was interrupted, verify it stopped before removing ' + lock);
    }
    throw error;
  }
  try {
    fs.writeFileSync(fd, String(process.pid));
    return write();
  } finally {
    fs.closeSync(fd);
    fs.unlinkSync(lock);
  }
}
