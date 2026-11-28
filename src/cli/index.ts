#!/usr/bin/env node

import { log } from "./log";
import { withProjectWrite } from "../project/config";

import { program } from "commander";
import { version } from "../../package.json";
import { addModule, removeModule, buildProject, pruneModules, watchProject, explainModule, regenerateApi } from "./commands";
import { initProject } from "./init";
import { interactiveSelect } from "./module-ui";

program.name("ltbridge").description("LT Bridge CLI tool for managing Lua modules and intellisense stubs").version(version);

program
	.command("init")
	.description("Initialize LTBridge in the current directory and generate Master API stubs")
	.action(async () => {
		const cwd = process.cwd();
		await initProject(cwd);
	});

const build = program
	.command("build")
	.alias("refresh")
	.alias("install")
	.alias("sync")
	.description("Resolve dependencies, rebuild bundles, and regenerate API stubs")
	.option("-w, --watch", "Watch project mode for continuous bundling")
	.option("-d, --details", "Show detailed bundling sequence")
	.action((options) => {
		const cwd = process.cwd();
		if (options.watch) {
			watchProject(cwd, options);
		} else {
			withProjectWrite(cwd, () => buildProject(cwd, options));
		}
	});

program.addHelpText("after", () => {
	const options = build.options.filter((option) => !option.hidden);
	const width = Math.max(...options.map((option) => option.flags.length));
	return "\nBuild Options:\n" + options.map((option) => "  " + option.flags.padEnd(width) + "  " + option.description).join("\n");
});

program
	.command("api")
	.description("Regenerate the API stubs for IDE intellisense (Internal use for developers)")
	.action(() => regenerateApi(process.cwd()));

program
	.command("add <name>")
	.description("Add a module to your project")
	.action((name: string) => {
		withProjectWrite(process.cwd(), () => addModule(process.cwd(), name));
	});

program
	.command("remove <name>")
	.description("Remove a module from your project")
	.action((name: string) => {
		withProjectWrite(process.cwd(), () => removeModule(process.cwd(), name));
	});

program
	.command("why <name>")
	.alias("explain")
	.description("Explain why a module is included in your project (dependency graph)")
	.action((name: string) => {
		explainModule(process.cwd(), name);
	});

program
	.command("list")
	.description("Select project modules interactively")
	.action(() => interactiveSelect(process.cwd()));

program
	.command("prune")
	.description("Prune unused modules from your project bundles")
	.action(() => {
		withProjectWrite(process.cwd(), () => pruneModules(process.cwd()));
	});

const args = process.argv.slice(2);
program.parseAsync(args.length === 0 ? ["--help"] : args, { from: "user" }).catch((error) => {
	log(error.message, "stderr");
	process.exitCode = 1;
});
