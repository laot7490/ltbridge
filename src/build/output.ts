import fs from 'node:fs';
import path from 'node:path';
import { writeFileAtomic } from '../project/config';

function isGenerated(content: string): boolean {
  return /^--\[\[\r?\n \* @license LT Bridge\r?\n/.test(content) ||
    /^-- LTBridge Auto-Generated (Shared|Client|Server) Loader\b/.test(content);
}

export function writeOutputs(root: string, outputs: Map<string, string>): void {
  const changed = new Map<string, string>();
  const directories = new Map<string, Map<string, fs.Dirent>>();
  if (fs.lstatSync(root, { throwIfNoEntry: false })?.isSymbolicLink()) throw new Error(`Cannot write generated output through symlink ${root}`);
  function entries(folder: string) {
    let result = directories.get(folder);
    if (!result) {
      try {
        result = new Map(fs.readdirSync(folder, { withFileTypes: true }).map((entry) => [entry.name, entry]));
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
        result = new Map();
      }
      directories.set(folder, result);
    }
    return result;
  }
  for (const [relative, content] of outputs) {
    const parts = relative.split('/');
    if (parts.some((segment) => segment === '..' || segment === '.')) throw new Error(`Invalid output path ${relative}`);
    let file = root;
    let entry: fs.Dirent | fs.Stats | undefined;
    for (const segment of parts) {
      const children = entries(file);
      entry = children.get(segment);
      if (!entry && process.platform === 'win32') {
        entry = fs.lstatSync(path.join(file, segment), { throwIfNoEntry: false });
      }
      file = path.join(file, segment);
      if (entry?.isSymbolicLink()) throw new Error(`Cannot write generated output through symlink ${file}`);
    }
    if (entry) {
      const previous = fs.readFileSync(file, 'utf8');
      if (previous === content) continue;
      if (!isGenerated(previous)) throw new Error(`Cannot replace user file ${file}`);
    }
    changed.set(file, content);
  }
  for (const [file, content] of changed) writeFileAtomic(file, content);
}

export function pruneOutputs(root: string, outputs: Map<string, string>): void {
  function prune(relative: string) {
    const folder = path.join(root, relative);
    for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
      const name = `${relative}/${entry.name}`;
      const file = path.join(root, name);
      if (entry.isDirectory()) prune(name);
      else if (entry.isFile() && name.endsWith('.lua') && !outputs.has(name) && isGenerated(fs.readFileSync(file, 'utf8'))) {
        fs.unlinkSync(file);
      }
    }
  }
  if (fs.lstatSync(path.join(root, 'modules'), { throwIfNoEntry: false })?.isDirectory()) prune('modules');
}
