import fs from "node:fs";
import path from "node:path";
import prompts from "prompts";
import { version } from "../../package.json";
import { rebuildAndSaveConfig } from "../build/index";
import { CONFIG_FILE, withProjectWrite, writeIfChanged } from "../project/config";
import { color, log } from "./log";

const LUA_IGNORE_DIR = "**/ltbridge/modules/**";

function ensureVscodeLuaIgnore(targetDir: string) {
	const vscodeDir = path.join(targetDir, ".vscode");
	const settingsPath = path.join(vscodeDir, "settings.json");
	let settings: Record<string, unknown> = {};
	if (fs.existsSync(settingsPath)) {
		try {
			settings = JSON.parse(fs.readFileSync(settingsPath, "utf-8"));
		} catch {
			log(`! Could not parse .vscode/settings.json — skipping Lua ignoreDir update.`, "yellow");
			return;
		}
	}
	const key = "Lua.workspace.ignoreDir";
	const existing = settings[key];
	const entries = Array.isArray(existing) ? existing : typeof existing === "string" ? [existing] : [];
	if (entries.includes(LUA_IGNORE_DIR)) {
		log("ℹ VS Code Lua ignoreDir already includes ltbridge/modules", "gray");
		return;
	}
	settings[key] = [...entries, LUA_IGNORE_DIR];
	writeIfChanged(settingsPath, JSON.stringify(settings, null, "\t") + "\n");
	log(`✓ Updated .vscode/settings.json (Lua.workspace.ignoreDir)`, "green");
}

export async function initProject(targetDir: string) {
	const configPath = path.join(targetDir, CONFIG_FILE);
	const originalConfig = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : undefined;

	if (originalConfig !== undefined) {
		const overwrite = await prompts({
			type: "confirm",
			name: "value",
			message: "LTBridge is already initialized. Do you want to overwrite the configuration?",
			initial: false,
		});
		if (!overwrite.value) {
			log(`! Initialization cancelled.`, "yellow");
			return;
		}
	}

	log(`\n${color(`⚡ ltbridge v${version}`, "cyan")} ${color(`Initializing project...`, "green")}\n`);

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
			initial: 1,
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
		{
			type: "confirm",
			name: "vscodeIgnore",
			message: "Add Lua.workspace.ignoreDir for ltbridge/modules to .vscode/settings.json?",
			initial: false,
		},
	]);

	if ([response.buildMode, response.minify, response.debug, response.vscodeIgnore].some((value) => typeof value !== "boolean")) {
		log(`! Initialization cancelled.`, "yellow");
		return;
	}

	const doBundle = response.buildMode === true;
	const doMinify = response.minify === true;
	const doDebug = response.debug === true;

	const initialConfig = {
		bundle: doBundle,
		debug: doDebug,
		minify: doMinify,
		modules: [],
	};
	withProjectWrite(targetDir, () => {
		const current = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : undefined;
		if (current !== originalConfig) throw new Error("LTBridge config changed during setup. Run init again.");
		rebuildAndSaveConfig(targetDir, initialConfig);
	});
	log(`\n${color(`✓ Created configuration: ${CONFIG_FILE}`, "green")}`);
	log(`ℹ Build Mode: ${doBundle ? "bundle" : "individual"}`, "gray");
	log(`ℹ Minify: ${doMinify ? "enabled" : "disabled"}`, "gray");
	log(`${color(`ℹ Debug: ${doDebug ? "enabled" : "disabled"}`, "gray")}\n`);

	if (response.vscodeIgnore) {
		ensureVscodeLuaIgnore(targetDir);
	}
}
