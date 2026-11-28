import { log } from "../cli/log";
import { version } from "../../package.json";
import fs from "node:fs";
import path from "node:path";
import type { Stats } from "node:fs";
import { watch } from "chokidar";
import { CONFIG_FILE, readProjectConfig, saveConfig, withProjectWrite, type ProjectConfig } from "./config";
import { readLuaReferences, isExcluded, resolveReferencedModules } from "./scan";

export function watchProject(root: string, rebuild: (config: ProjectConfig) => void) {
	readProjectConfig(root);
	const configFile = path.join(root, CONFIG_FILE);
	const callsByFile = new Map<string, Set<string>>();
	const calls = new Map<string, number>();
	let timer: ReturnType<typeof setTimeout> | undefined;
	let ready = false;
	let retry = false;
	let lastBuild: string | undefined;

	function scheduleSync() {
		clearTimeout(timer);
		timer = setTimeout(sync, 100);
	}

	function replaceCalls(file: string, next?: Set<string>) {
		for (const call of callsByFile.get(file) ?? []) {
			const count = calls.get(call)! - 1;
			if (count === 0) calls.delete(call);
			else calls.set(call, count);
		}
		if (next) {
			callsByFile.set(file, next);
			for (const call of next) calls.set(call, (calls.get(call) ?? 0) + 1);
		} else callsByFile.delete(file);
	}

	function sync() {
		try {
			withProjectWrite(root, syncProject);
		} catch (error) {
			retry = true;
			log(`Watcher error: ${error instanceof Error ? error.message : error}`, "stderr");
		}
	}

	function syncProject() {
		const config = readProjectConfig(root);
		const modules = new Set(config.modules);
		const previousSize = modules.size;
		for (const module of calls.keys()) modules.add(module);
		const changed = previousSize !== config.modules.length || modules.size !== previousSize;
		if (changed) config.modules = [...modules];
		const snapshot = JSON.stringify([config.modules, config.bundle, config.debug, config.minify]);
		const previousVersion = config.version;
		if (snapshot !== lastBuild || config.version !== version || !fs.existsSync(path.join(root, "ltbridge", "api.lua")))
			rebuild(config);
		if (changed || config.version !== previousVersion) {
			saveConfig(root, config);
		}
		lastBuild = snapshot;
		retry = false;
	}

	const watcher = watch(root, {
		ignored: (file: string, stats?: Stats) =>
			isExcluded(root, path.resolve(file)) ||
			(stats?.isFile() === true && !file.endsWith(".lua") && path.resolve(file) !== configFile),
		followSymlinks: false,
		awaitWriteFinish: { stabilityThreshold: 100, pollInterval: 25 },
	});
	watcher.on("all", (event, file) => {
		const absolute = path.resolve(file);
		if (event !== "add" && event !== "change" && event !== "unlink") return;
		if (absolute !== configFile) {
			if (!absolute.endsWith(".lua")) return;
			try {
				const previous = callsByFile.get(absolute);
				const next =
					event === "unlink" || !fs.existsSync(absolute) ? undefined : resolveReferencedModules(readLuaReferences(absolute));
				const unchanged = previous && next && previous.size === next.size && [...next].every((call) => previous.has(call));
				if (unchanged && !retry) return;
				if (!unchanged) replaceCalls(absolute, next);
			} catch (error) {
				log(`Could not scan ${absolute}: ${String(error)}`, "stderr");
				return;
			}
		}
		if (ready) scheduleSync();
	});
	watcher.on("ready", () => {
		ready = true;
		sync();
		log(`Watching Lua files in ${root} (Ctrl+C to stop)`);
	});
	watcher.on("error", (error) => log(`Watcher error: ${String(error)}`, "stderr"));
	return watcher;
}
