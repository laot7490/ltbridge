import fs from "node:fs";
import path from "node:path";
import { writeFileAtomic } from "../project/config";

export function writeOutputs(root: string, outputs: Map<string, string>): Set<string> {
	const changed = new Map<string, string>();
	const expectedPaths = new Set(outputs.keys());
	const directories = new Map<string, Map<string, fs.Dirent> | undefined>();
	if (fs.lstatSync(root, { throwIfNoEntry: false })?.isSymbolicLink())
		throw new Error(`Cannot write generated output through symlink ${root}`);
	function entries(folder: string) {
		if (directories.has(folder)) return directories.get(folder);
		let result: Map<string, fs.Dirent> | undefined;
		try {
			result = new Map(fs.readdirSync(folder, { withFileTypes: true }).map((entry) => [entry.name, entry]));
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
			// An absent directory has no descendant paths to inspect.
		}
		directories.set(folder, result);
		return result;
	}
	for (const [relative, content] of outputs) {
		const parts = relative.split("/");
		if (parts.some((segment) => segment === ".." || segment === ".")) throw new Error(`Invalid output path ${relative}`);
		let parent = root;
		const file = path.join(root, ...parts);
		let entry: fs.Dirent | fs.Stats | undefined;
		let usedWindowsLookup = false;
		for (const segment of parts) {
			const children = entries(parent);
			if (!children) {
				entry = undefined;
				break;
			}
			entry = children.get(segment);
			if (!entry && process.platform === "win32") {
				entry = fs.lstatSync(path.join(parent, segment), { throwIfNoEntry: false });
				if (entry) usedWindowsLookup = true;
			}
			parent = path.join(parent, segment);
			if (entry?.isSymbolicLink()) throw new Error(`Cannot write generated output through symlink ${parent}`);
		}
		if (entry) {
			if (usedWindowsLookup) {
				const actual = path.relative(fs.realpathSync.native(root), fs.realpathSync.native(file));
				expectedPaths.add(actual.replaceAll(path.sep, "/"));
			}
			if (fs.readFileSync(file, "utf8") === content) continue;
		}
		changed.set(file, content);
	}
	for (const [file, content] of changed) writeFileAtomic(file, content);
	return expectedPaths;
}

export function pruneOutputs(root: string, expectedPaths: Set<string>): void {
	function prune(relative: string): boolean {
		let hasEntries = false;
		const folder = path.join(root, relative);
		for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
			const name = `${relative}/${entry.name}`;
			const file = path.join(root, name);
			if (entry.isDirectory()) {
				if (prune(name)) hasEntries = true;
			} else if (entry.isFile() && name.endsWith(".lua") && !expectedPaths.has(name)) {
				fs.unlinkSync(file);
			} else hasEntries = true;
		}
		if (!hasEntries && relative !== "modules" && fs.readdirSync(folder).length === 0) {
			fs.rmdirSync(folder);
			return false;
		}
		return true;
	}
	if (fs.lstatSync(path.join(root, "modules"), { throwIfNoEntry: false })?.isDirectory()) prune("modules");
}
