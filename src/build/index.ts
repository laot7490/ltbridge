import { color, log } from "../cli/log";
import fs from "node:fs";
import path from "node:path";
import { version } from "../../package.json";
import { resolveDependencies } from "../catalog/resolve";
import { saveConfig, type ProjectConfig } from "../project/config";
import { generateFullApi } from "./api";
import { prepareManifest } from "./manifest";
import { renderBundle } from "./render";
import { pruneOutputs, writeOutputs } from "./output";

export interface BuildOptions {
	details?: boolean;
}

export function rebuildBundle(targetDir: string, config: ProjectConfig, options: BuildOptions = {}) {
	const startTime = Date.now();
	const explicitModules = config.modules;
	const buildAsIndividual = config.bundle !== true;

	const { sequence } = resolveDependencies(explicitModules);
	const loadSequence = ["__init__", ...sequence.filter((name) => name !== "__init__")];

	if (options.details) {
		log(`\n${color(`📦 Bundling Sequence (${loadSequence.length} modules):`, "sequence")}`);
		loadSequence.forEach((mod, index) => log(`  ${color(`${(index + 1).toString().padStart(2, "0")}.`, "gray")} ${mod}`));
		log("");
	}

	const { outputs, hasClient, hasServer, hasShared } = renderBundle(loadSequence, config);
	const ltModulesDir = path.join(targetDir, "ltbridge");
	const applyManifest = prepareManifest(targetDir, hasClient, hasServer, hasShared, buildAsIndividual);
	const expectedPaths = writeOutputs(ltModulesDir, outputs);
	applyManifest?.();
	pruneOutputs(ltModulesDir, expectedPaths);
	if (config.version !== version || !fs.existsSync(path.join(ltModulesDir, "api.lua"))) {
		generateFullApi(targetDir);
		config.version = version;
	}

	log(`${color(`✓`, "green")} ${loadSequence.length} modules bundled in ${Date.now() - startTime}ms`);
}

export function rebuildAndSaveConfig(targetDir: string, config: ProjectConfig) {
	rebuildBundle(targetDir, config);
	saveConfig(targetDir, config);
}
