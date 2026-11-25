import fs from "node:fs";
import path from "node:path";
import { version } from "../../package.json";
import { resolveDependencies } from "../catalog/resolve";
import type { ProjectConfig } from "../project/config";
import { generateFullApi } from "./api";
import { prepareManifest } from "./manifest";
import { renderBundle } from "./render";
import { pruneOutputs, writeOutputs } from "./output";

export interface BuildOptions { details?: boolean }

export function rebuildBundle(targetDir: string, config: ProjectConfig, options: BuildOptions = {}) {

	const startTime = Date.now();
	const explicitModules = config.modules || [];
	const buildAsIndividual = config.bundle !== true;

	let loadSequence: string[] = [];

	if (explicitModules.length > 0) {
		const result = resolveDependencies(explicitModules);
		loadSequence = result.sequence;
	}

	loadSequence = ["__init__", ...loadSequence.filter((m) => m !== "__init__")];

	if (options.details) {
		console.log(`\n\x1b[1m\x1b[35m📦 Bundling Sequence (${loadSequence.length} modules):\x1b[0m`);
		loadSequence.forEach((mod, index) => console.log(`  \x1b[90m${(index + 1).toString().padStart(2, "0")}.\x1b[0m ${mod}`));
		console.log("");
	}

	const { outputs, hasClient, hasServer, hasShared } = renderBundle(loadSequence, config);
	const ltModulesDir = path.join(targetDir, "ltbridge");
	const applyManifest = prepareManifest(targetDir, hasClient, hasServer, hasShared, buildAsIndividual);
	writeOutputs(ltModulesDir, outputs);
	applyManifest?.();
	pruneOutputs(ltModulesDir, outputs);
	if (config.version !== version || !fs.existsSync(path.join(ltModulesDir, "api.lua"))) {
		generateFullApi(targetDir);
		config.version = version;
	}

	console.log(`\x1b[32m✓\x1b[0m ${loadSequence.length} modules bundled in ${Date.now() - startTime}ms`);
}
