const fs = require("fs-extra");
const path = require("path");
const { version } = require("../package.json");
const { rebuildBundle, generateFullApi, getModuleExportMap } = require("./bundler");
const { resolveDependencies } = require("./moduleResolver");
const { getModuleRegistry, getModuleData } = require("./registry");
const { pickExportModule } = require("./resolveExport");
const { getVisibleModules, buildModuleGroups, getDependencySets, getFilteredSortedMods } = require("./moduleListUi");
const prompts = require("prompts");

const CONFIG_FILE = path.join("ltbridge", "ltbridge.config.json");

async function initProject(targetDir, options = {}) {
	const configPath = path.join(targetDir, CONFIG_FILE);
	let alreadyInitialized = fs.existsSync(configPath);

	if (alreadyInitialized) {
		const overwrite = await prompts({
			type: "confirm",
			name: "value",
			message: "LTBridge is already initialized. Do you want to overwrite the configuration?",
			initial: false,
		});
		if (!overwrite.value) {
			console.log(`\x1b[33m! Initialization cancelled.\x1b[0m`);
			return;
		}
	}

	console.log(`\n\x1b[36m⚡ ltbridge v${version}\x1b[0m \x1b[32mInitializing project...\x1b[0m\n`);

	let doMinify = options.minify !== false;
	let doDebug = options.debug === true;
	let doBundle = false;

	const isInteractive = !process.argv.includes("--no-minify") && !process.argv.includes("--debug");

	if (isInteractive) {
		const response = await prompts([
			{
				type: "select",
				name: "buildMode",
				message: "Build Output Mode:",
				choices: [
					{ title: "Individual (Separate files per module)", value: false },
					{ title: "Bundle (Combine all into 3 files)", value: true },
				],
				initial: 0,
			},
			{
				type: "select",
				name: "minify",
				message: "Bundled code minification:",
				choices: [
					{ title: "Enabled (Compact production code)", value: true },
					{ title: "Disabled (Readable development code)", value: false },
				],
				initial: 0,
			},
			{
				type: "select",
				name: "debug",
				message: "Runtime debug mode:",
				choices: [
					{ title: "Disabled (Recommended for production)", value: false },
					{ title: "Enabled (Detailed logs and helper outputs)", value: true },
				],
				initial: 0,
			},
		]);

		if (response.buildMode !== undefined) doBundle = response.buildMode;
		if (response.minify !== undefined) doMinify = response.minify;
		if (response.debug !== undefined) doDebug = response.debug;
	}

	const initialConfig = {
		version: version,
		buildAsBundle: doBundle,
		debug: doDebug,
		minify: doMinify,
		modules: [],
	};

	fs.ensureDirSync(path.dirname(configPath));
	fs.writeFileSync(configPath, JSON.stringify(initialConfig, null, 2));
	console.log(`\n\x1b[32m✓ Created configuration: ${CONFIG_FILE}\x1b[0m`);
	console.log(`\x1b[90mℹ Build Mode: ${doBundle ? "bundle" : "individual"}\x1b[0m`);
	console.log(`\x1b[90mℹ Minify: ${doMinify ? "enabled" : "disabled"}\x1b[0m`);
	console.log(`\x1b[90mℹ Debug: ${doDebug ? "enabled" : "disabled"}\x1b[0m\n`);

	generateFullApi(targetDir);

	if (options.noBuild !== true) {
		rebuildBundle(targetDir, initialConfig);
	}
}

function getConfig(targetDir) {
	const configPath = path.join(targetDir, CONFIG_FILE);
	if (!fs.existsSync(configPath)) {
		console.log(`\x1b[31m✖ Not an LTBridge initialized directory. Run 'ltbridge init' first.\x1b[0m`);
		process.exit(1);
	}
	return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

function saveConfig(targetDir, config) {
	const configPath = path.join(targetDir, CONFIG_FILE);
	fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

function resolveWildcardModules(moduleName, registry) {
	if (!moduleName.endsWith("*")) {
		const single = resolveModuleName(moduleName, registry);
		return single ? [single] : [];
	}

	const prefix = moduleName.replace(/\\/g, "/").replace(/^@/, "").replace(/\*$/, "").toLowerCase();
	const matches = [];
	for (const key of Object.keys(registry)) {
		if (key === "__init__") continue;
		const normalizedKey = key.replace(/^@/, "").toLowerCase();
		if (normalizedKey.startsWith(prefix)) {
			let isInternal = false;
			const modData = getModuleData(key);
			if (modData && modData.meta) {
				isInternal = modData.meta.internal === true;
			}
			if (!isInternal) {
				matches.push(key);
			}
		}
	}
	return matches;
}

function resolveModuleName(moduleName, registry) {
	if (registry[moduleName]) return moduleName;
	const normalizedInput = moduleName.replace(/\\/g, "/").replace(/^@/, "").toLowerCase();

	const matches = [];
	for (const key of Object.keys(registry)) {
		const normalizedKey = key.replace(/^@/, "").toLowerCase();
		if (normalizedKey === normalizedInput) return key;

		const parts = key.split("/");
		const lastPart = parts[parts.length - 1].toLowerCase();
		if (lastPart === normalizedInput || lastPart === normalizedInput.replace(/^@/, "")) {
			matches.push(key);
		}
	}

	if (matches.length === 1) return matches[0];
	if (matches.length > 1) {
		console.log(`\x1b[31m✖ Ambiguous module name '${moduleName}'.\x1b[0m`);
		console.log(`\x1b[90mℹ Did you mean one of these?\x1b[0m`);
		matches.forEach((m) => console.log(`  - ${m.replace(/^@/, "")}`));
		process.exit(1);
	}

	// Try export map if folder name doesn't match
	const exportMap = getModuleExportMap();
	const cleanName = moduleName.replace(/^LT\./, "");
	if (exportMap[cleanName]) {
		const candidates = exportMap[cleanName];
		if (candidates.length === 1) return candidates[0];

		console.log(`\x1b[31m✖ Ambiguous export name '${moduleName}' provided by multiple modules.\x1b[0m`);
		console.log(`\x1b[90mℹ Please use the full module path to add it:\x1b[0m`);
		candidates.forEach((c) => console.log(`  - ltbridge add ${c.replace(/^@/, "")}`));
		process.exit(1);
	}

	return null;
}

function addModule(targetDir, moduleName) {
	const config = getConfig(targetDir);
	const registry = getModuleRegistry();
	const resolvedNames = resolveWildcardModules(moduleName, registry);

	if (resolvedNames.length === 0) {
		console.log(`\x1b[31m✖ No modules found matching '${moduleName}'.\x1b[0m`);
		process.exit(1);
	}

	let addedCount = 0;
	let internalBlocked = false;

	for (const resolvedName of resolvedNames) {
		if (resolvedName === "__init__") continue;

		let isInternal = false;
		const modData = getModuleData(resolvedName);
		if (modData && modData.meta) {
			isInternal = modData.meta.internal === true;
		}

		if (isInternal) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[31m✖ Cannot manually add internal ghost module '${resolvedName}'.\x1b[0m`);
				console.log(
					`\x1b[90mℹ Ghost modules are active and managed purely as auto-dependencies behind the scenes.\x1b[0m`,
				);
				internalBlocked = true;
			}
			continue;
		}

		if (config.modules.includes(resolvedName)) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[90mℹ Module '${resolvedName}' is already added.\x1b[0m`);
			}
			continue;
		}

		config.modules.push(resolvedName);
		console.log(`\x1b[32m✓ Added module '${resolvedName}'.\x1b[0m`);
		addedCount++;
	}

	if (addedCount > 0) {
		saveConfig(targetDir, config);
		rebuildBundle(targetDir, config, { skipApi: true });
	} else if (moduleName.endsWith("*")) {
		if (internalBlocked) {
			console.log(
				`\x1b[31m✖ No addable modules matched '${moduleName}' (internal-only modules are auto-managed).\x1b[0m`,
			);
			process.exit(1);
		}
		console.log(`\x1b[90mℹ All matching modules are already added.\x1b[0m`);
	} else if (internalBlocked) {
		process.exit(1);
	}
}

function removeModule(targetDir, moduleName) {
	const config = getConfig(targetDir);
	const registry = getModuleRegistry();
	const resolvedNames = resolveWildcardModules(moduleName, registry);

	if (resolvedNames.length === 0) {
		console.log(`\x1b[31m✖ No modules found matching '${moduleName}'.\x1b[0m`);
		process.exit(1);
	}

	let removedCount = 0;

	for (const resolvedName of resolvedNames) {
		if (!config.modules.includes(resolvedName)) {
			if (!moduleName.endsWith("*")) {
				console.log(`\x1b[90mℹ Module '${resolvedName}' is not currently added.\x1b[0m`);
			}
			continue;
		}

		config.modules = config.modules.filter((m) => m !== resolvedName);
		console.log(`\x1b[33m- Removed module '${resolvedName}'.\x1b[0m`);
		removedCount++;
	}

	if (removedCount > 0) {
		saveConfig(targetDir, config);
		rebuildBundle(targetDir, config, { skipApi: true });
	} else if (moduleName.endsWith("*")) {
		console.log(`\x1b[90mℹ No matching modules were currently added.\x1b[0m`);
	}
}

function refreshModules(targetDir, options = {}) {
	const config = getConfig(targetDir);
	console.log(`\n\x1b[36m⚡ ltbridge v${version}\x1b[0m \x1b[32mbuilding for production...\x1b[0m`);
	rebuildBundle(targetDir, config, options);
}

function scanLuaCalls(dir) {
	const foundCalls = new Set();
	function search(currentDir) {
		if (!fs.existsSync(currentDir)) return;
		const files = fs.readdirSync(currentDir);
		for (const file of files) {
			if (file === "ltbridge" || file === "node_modules" || file === ".git") continue;
			const fullPath = path.join(currentDir, file);
			const stat = fs.statSync(fullPath);
			if (stat.isDirectory()) {
				search(fullPath);
			} else if (file.endsWith(".lua")) {
				const content = fs.readFileSync(fullPath, "utf8");
				const regex = /LT\.([a-zA-Z0-9_.]+)/g;
				let match;
				while ((match = regex.exec(content)) !== null) {
					const callPath = match[1];
					foundCalls.add(callPath);
					const parts = callPath.split(".");
					let current = "";
					for (const part of parts) {
						current = current ? current + "." + part : part;
						foundCalls.add(current);
					}
				}
			}
		}
	}
	search(dir);
	return foundCalls;
}

function resolveCallsToModules(foundCalls) {
	const registry = getModuleRegistry();
	const availableModules = Object.keys(registry);
	const exportMap = getModuleExportMap();
	const validRequestedModules = new Set();

	for (const call of foundCalls) {
		const pathForm = "@" + call.replace(/\./g, "/");

		// Direct module path match
		if (availableModules.includes(pathForm)) {
			validRequestedModules.add(pathForm);
			continue;
		}

		if (exportMap[call]) {
			const match = pickExportModule(call, exportMap[call]);
			if (match) validRequestedModules.add(match);
		}
	}
	return validRequestedModules;
}

function pruneModules(targetDir) {
	const config = getConfig(targetDir);
	console.log(`\x1b[90mℹ Scanning project for unused LT modules...\x1b[0m`);

	const foundCalls = scanLuaCalls(targetDir);
	const validRequestedModules = resolveCallsToModules(foundCalls);

	const toKeep = [];
	const removed = [];

	for (const m of config.modules) {
		if (validRequestedModules.has(m)) {
			toKeep.push(m);
		} else {
			removed.push(m);
		}
	}

	if (removed.length > 0) {
		console.log(`\x1b[32m✓ Pruned ${removed.length} unused modules: ${removed.join(", ")}\x1b[0m`);
		config.modules = toKeep;
		saveConfig(targetDir, config);
	} else {
		console.log(`\x1b[90mℹ No unused modules found. Everything is tightly integrated!\x1b[0m`);
	}

	rebuildBundle(targetDir, config, { skipApi: true });
}

let watchTimeout = null;
let watchIsSyncing = false;
let watchPendingSync = false;

function isWatcherIgnoredPath(targetDir, filePath) {
	if (!filePath) return true;

	const rootDir = path.resolve(targetDir);
	const absPath = path.resolve(path.isAbsolute(filePath) ? filePath : path.join(rootDir, filePath));
	const rel = path.relative(rootDir, absPath).replace(/\\/g, "/");

	if (rel === "" || rel === ".") return false;
	if (rel.startsWith("..")) return true;
	if (rel.includes("node_modules")) return true;
	if (rel === "ltbridge/modules" || rel.startsWith("ltbridge/modules/")) return true;
	if (rel === "ltbridge/api.lua") return true;
	if (rel === "fxmanifest.lua" || rel === "__resource.lua") return true;
	if (rel.endsWith("ltbridge.config.json")) return false;

	let stat;
	try {
		stat = fs.statSync(absPath);
	} catch {
		return true;
	}

	if (stat.isDirectory()) return false;
	return !rel.endsWith(".lua");
}

function watchProject(targetDir, options = {}) {
	let lastConfigState = "";
	const configPath = path.join(targetDir, CONFIG_FILE);
	if (fs.existsSync(configPath)) {
		lastConfigState = fs.readFileSync(configPath, "utf-8");
	}

	function syncModules(forceRebuild = false) {
		if (watchIsSyncing) {
			watchPendingSync = true;
			return;
		}

		const currentConfig = getConfig(targetDir);
		const foundModules = scanLuaCalls(targetDir);
		const validRequestedModules = resolveCallsToModules(foundModules);

		let changed = false;
		const newConfigModules = new Set(currentConfig.modules);

		for (const mod of validRequestedModules) {
			if (!newConfigModules.has(mod)) {
				newConfigModules.add(mod);
				changed = true;
			}
		}

		for (const mod of currentConfig.modules) {
			if (!validRequestedModules.has(mod)) {
				newConfigModules.delete(mod);
				changed = true;
			}
		}

		if (!changed && !forceRebuild) return;

		watchIsSyncing = true;
		try {
			if (changed) {
				currentConfig.modules = Array.from(newConfigModules);
			}
			lastConfigState = JSON.stringify(currentConfig, null, 2);
			if (changed) saveConfig(targetDir, currentConfig);

			rebuildBundle(targetDir, currentConfig, { skipApi: true, ...options });
		} finally {
			watchIsSyncing = false;
			if (watchPendingSync) {
				watchPendingSync = false;
				scheduleWatchSync();
			}
		}
	}

	function scheduleWatchSync() {
		if (watchTimeout) clearTimeout(watchTimeout);
		watchTimeout = setTimeout(() => {
			try {
				syncModules(true);
			} catch (e) {
				console.log(`\x1b[31m✖ Watcher error: ${e.message}\x1b[0m`);
			}
		}, 400);
	}

	console.log(`\n\x1b[36m⚡ ltbridge v${version}\x1b[0m \x1b[32mwatching for changes...\x1b[0m`);
	syncModules(true);

	const chokidar = require("chokidar");
	const watcher = chokidar.watch(targetDir, {
		ignored: (filePath) => isWatcherIgnoredPath(targetDir, filePath),
		persistent: true,
		ignoreInitial: true,
		awaitWriteFinish: {
			stabilityThreshold: 150,
			pollInterval: 50,
		},
	});

	watcher.on("ready", () => {
		console.log(`\x1b[90mℹ Watching Lua files in ${path.resolve(targetDir)} (Ctrl+C to stop)\x1b[0m\n`);
	});

	watcher.on("error", (err) => {
		console.log(`\x1b[31m✖ Watcher error: ${err.message}\x1b[0m`);
	});

	watcher.on("all", (event, filename) => {
		if (watchIsSyncing) return;
		if (!filename || isWatcherIgnoredPath(targetDir, filename)) return;
		if (event !== "change" && event !== "add") return;

		const absPath = path.isAbsolute(filename) ? filename : path.join(targetDir, filename);
		const rel = path.relative(targetDir, absPath).replace(/\\/g, "/");
		const isConfig = rel.endsWith("ltbridge.config.json") || rel === path.basename(CONFIG_FILE).replace(/\\/g, "/");

		if (isConfig) {
			try {
				const currentStr = fs.readFileSync(configPath, "utf-8");
				if (currentStr === lastConfigState) return;
			} catch (e) {
				return;
			}
		}

		scheduleWatchSync();
	});
}

function listModules(targetDir) {
	const registry = getModuleRegistry();
	const allModules = getVisibleModules();

	let currentConfig = null;
	const configPath = path.join(targetDir, CONFIG_FILE);
	if (fs.existsSync(configPath)) {
		try {
			currentConfig = JSON.parse(fs.readFileSync(configPath, "utf-8"));
		} catch (e) {}
	}

	const installed = currentConfig ? new Set(currentConfig.modules) : new Set();
	const depsSet = getDependencySets(currentConfig ? currentConfig.modules : []);

	const allModulesSet = new Set(allModules);
	const visibleInstalled = new Set([...installed].filter((m) => allModulesSet.has(m)));
	const visibleDeps = new Set([...depsSet].filter((m) => allModulesSet.has(m) && !visibleInstalled.has(m)));

	const totalActiveSize = visibleInstalled.size + visibleDeps.size;

	console.log(
		`\n\x1b[1m\x1b[36mℹ LTBridge Modules List (${visibleInstalled.size} manual + ${visibleDeps.size} auto = ${totalActiveSize} active / ${allModules.length} total)\x1b[0m\n`,
	);

	if (allModules.length === 0) {
		console.log("  No modules found in the repository.");
		return;
	}

	const groups = buildModuleGroups(allModules, registry);

	for (const group of Object.keys(groups).sort()) {
		console.log(`\n  \x1b[1m\x1b[35m📁 ${group}\x1b[0m`);

		const sortedMods = getFilteredSortedMods(groups[group], group);

		for (const { mod, name } of sortedMods) {
			const isInstalled = installed.has(mod);
			const isDep = depsSet.has(mod);

			let icon = " ";
			let color = "\x1b[90m";

			if (isInstalled) {
				icon = "✔";
				color = "\x1b[32m";
			} else if (isDep) {
				icon = "⚙";
				color = "\x1b[33m";
			}

			process.stdout.write(`    ${color}${icon} ${name.padEnd(30)}\x1b[0m`);

			if (isDep && !isInstalled) {
				process.stdout.write(` \x1b[90m⚙ Auto-Dependency\x1b[0m`);
			} else if (isDep && isInstalled) {
				process.stdout.write(` \x1b[90m(Also a Dependency)\x1b[0m`);
			}
			process.stdout.write("\n");
		}
	}

	console.log(`\n\x1b[90m(✔ = Installed | ⚙ = Auto Dependency)\x1b[0m\n`);
}

async function interactiveSelect(targetDir) {
	const registry = getModuleRegistry();
	const allModules = getVisibleModules();

	let currentConfig = null;
	const configPath = path.join(targetDir, CONFIG_FILE);
	if (fs.existsSync(configPath)) {
		try {
			currentConfig = JSON.parse(fs.readFileSync(configPath, "utf-8"));
		} catch (e) {}
	}

	if (!currentConfig) {
		console.log(`\x1b[31m✖ Not an LTBridge initialized directory. Run 'ltbridge init' first.\x1b[0m`);
		return;
	}

	const installed = new Set(currentConfig.modules || []);
	const depsSet = getDependencySets(currentConfig.modules || []);
	const groups = buildModuleGroups(allModules, registry);

	const choices = [];
	for (const group of Object.keys(groups).sort()) {
		choices.push({
			title: `\x1b[1m\x1b[36m--- ${group.toUpperCase()} ---\x1b[0m`,
			value: `__group_${group}__`,
			disabled: true,
		});

		const sortedMods = getFilteredSortedMods(groups[group], group);

		for (const { mod, name } of sortedMods) {
			const isInstalled = installed.has(mod);
			const isDep = depsSet.has(mod);

			let title = name;
			if (isDep && !isInstalled) {
				title = `${title} \x1b[90m(⚙ Auto-Dependency [INCLUDED])\x1b[0m`;
			} else if (isDep && isInstalled) {
				title = `${title} \x1b[90m(Also a Dependency)\x1b[0m`;
			}

			choices.push({
				title: title,
				value: mod,
				selected: isInstalled,
				disabled: isDep && !isInstalled,
			});
		}
	}

	const response = await prompts({
		type: "multiselect",
		name: "selectedModules",
		message: "Select LTBridge modules",
		choices: choices,
		instructions: false,
		hint: "- [Space] select. [Return] submit",
		min: 0,
	});

	if (!response.selectedModules) {
		console.log(`\x1b[90mℹ Module selection cancelled.\x1b[0m`);
		return;
	}

	const finalSelection = response.selectedModules.filter((m) => !m.startsWith("__group_"));
	const toAdd = finalSelection.filter((m) => !installed.has(m));
	const toRemove = Array.from(installed).filter((m) => !finalSelection.includes(m));

	if (toAdd.length === 0 && toRemove.length === 0) {
		console.log(`\x1b[90mℹ No changes made to module selection.\x1b[0m`);
		return;
	}

	if (toAdd.length > 0) console.log(`\x1b[32m✓ Adding: ${toAdd.join(", ")}\x1b[0m`);
	if (toRemove.length > 0) console.log(`\x1b[33m- Removing: ${toRemove.join(", ")}\x1b[0m`);

	currentConfig.modules = finalSelection;
	saveConfig(targetDir, currentConfig);

	rebuildBundle(targetDir, currentConfig, { skipApi: true });
}

function explainModule(targetDir, moduleName) {
	const registry = getModuleRegistry();
	const resolvedName = resolveModuleName(moduleName, registry);

	if (!resolvedName) {
		console.log(`\x1b[31m✖ Module '${moduleName}' does not exist in the repository.\x1b[0m`);
		process.exit(1);
	}

	const configPath = path.join(targetDir, CONFIG_FILE);
	if (!fs.existsSync(configPath)) {
		console.log(`\x1b[31m✖ Not an LTBridge initialized directory. Run 'ltbridge init' first.\x1b[0m`);
		return;
	}

	let config = { modules: [] };
	try {
		config = JSON.parse(fs.readFileSync(configPath, "utf-8"));
	} catch (e) {}

	const installed = new Set(config.modules || []);
	const { graph } = resolveDependencies(config.modules || [], getModuleExportMap());

	const dependentOf = {};
	for (const [parentModule, deps] of Object.entries(graph)) {
		for (const d of deps) {
			if (!dependentOf[d]) dependentOf[d] = [];
			if (!dependentOf[d].includes(parentModule)) dependentOf[d].push(parentModule);
		}
	}

	const isManual = installed.has(resolvedName);
	const parents = dependentOf[resolvedName] || [];
	const isDep = parents.length > 0;

	console.log(`\n\x1b[1m\x1b[36mℹ Why is '${resolvedName}' included in your project?\x1b[0m`);

	if (!isManual && !isDep) {
		console.log(`  \x1b[90m○ This module is NOT currently included in your project build.\x1b[0m\n`);
		return;
	}

	if (isManual) {
		console.log(`  \x1b[32m✔ You explicitly added it to your ltbridge.config.json\x1b[0m`);
	}

	if (isDep) {
		console.log(`  \x1b[33m⚙ It is automatically included as a dependency for the following modules:\x1b[0m`);
		for (const p of parents) {
			console.log(`    - ${p}`);
		}
	}
	console.log("");
}

module.exports = {
	initProject,
	addModule,
	removeModule,
	refreshModules,
	pruneModules,
	watchProject,
	generateFullApi,
	listModules,
	interactiveSelect,
	explainModule,
};
