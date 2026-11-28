import { color, log } from "./log";
import prompts from "prompts";
import { readProjectConfig, withProjectWrite } from "../project/config";
import { rebuildAndSaveConfig } from "../build/index";
interface ModuleEntry {
	mod: string;
	name: string;
}
import { getModuleRegistry, isPublicModule } from "../catalog/database";
import { resolveDependencies } from "../catalog/resolve";

function buildModuleGroups(allModules: string[], registry: Record<string, string>) {
	const groups: Record<string, ModuleEntry[]> = {};

	for (const mod of allModules) {
		const registryPath = registry[mod];
		const groupTokens = [];

		if (registryPath) {
			const parts = registryPath.split("/");
			for (let i = 0; i < parts.length - 1; i++) {
				let token = parts[i];
				if (token.startsWith("@") || token.startsWith("#")) {
					token = token.substring(1);
				}
				groupTokens.push(token);
			}
		}

		const group = groupTokens.length > 0 ? groupTokens.join(" / ") : "Uncategorized";
		const name = mod.split("/").at(-1)!;

		if (!groups[group]) groups[group] = [];
		groups[group].push({ mod, name });
	}

	return groups;
}

function getVisibleGroupModules(modsInGroup: ModuleEntry[], group: string) {
	const lastPart = group.split(" / ").pop();
	const initModName = "@" + lastPart;
	const filteredMods = modsInGroup.length > 1 ? modsInGroup.filter((m) => m.mod !== initModName) : modsInGroup;
	return filteredMods.sort((a, b) => a.name.localeCompare(b.name));
}

export async function interactiveSelect(targetDir: string) {
	const registry = getModuleRegistry();
	const allModules = Object.keys(registry).filter(isPublicModule);

	const currentConfig = readProjectConfig(targetDir, true);

	if (!currentConfig) {
		log(`✖ Not an LTBridge initialized directory. Run 'ltbridge init' first.`, "red");
		return;
	}

	const installed = new Set(currentConfig.modules);
	const depsSet = new Set(Object.values(resolveDependencies(currentConfig.modules).graph).flat());
	const groups = buildModuleGroups(allModules, registry);

	const choices: prompts.Choice[] = [];
	for (const group of Object.keys(groups).sort()) {
		choices.push({
			title: `${color(`--- ${group.toUpperCase()} ---`, "heading")}`,
			value: `__group_${group}__`,
			disabled: true,
		});

		const sortedMods = getVisibleGroupModules(groups[group], group);

		for (const { mod, name } of sortedMods) {
			const isInstalled = installed.has(mod);
			const isDep = depsSet.has(mod);

			let title = name;
			if (isDep && !isInstalled) {
				title = `${title} ${color(`(⚙ Auto-Dependency [INCLUDED])`, "gray")}`;
			} else if (isDep && isInstalled) {
				title = `${title} ${color(`(Also a Dependency)`, "gray")}`;
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
		log(`ℹ Module selection cancelled.`, "gray");
		return;
	}

	const selectableModules = new Set(choices.filter((choice) => !choice.disabled).map((choice) => choice.value));
	const selected = new Set<string>(response.selectedModules.filter((id: string) => selectableModules.has(id)));
	const finalSelection = currentConfig.modules.filter((id) => !selectableModules.has(id) || selected.has(id));
	for (const id of selected) if (!installed.has(id)) finalSelection.push(id);
	const toAdd = finalSelection.filter((m) => !installed.has(m));
	const toRemove = Array.from(installed).filter((m) => !finalSelection.includes(m));

	if (toAdd.length === 0 && toRemove.length === 0) {
		log(`ℹ No changes made to module selection.`, "gray");
		return;
	}

	if (toAdd.length > 0) log(`✓ Adding: ${toAdd.join(", ")}`, "green");
	if (toRemove.length > 0) log(`- Removing: ${toRemove.join(", ")}`, "yellow");

	withProjectWrite(targetDir, () => {
		const latest = readProjectConfig(targetDir);
		if (JSON.stringify(latest) !== JSON.stringify(currentConfig))
			throw new Error("LTBridge config changed during selection. Open the picker again.");
		latest.modules = finalSelection;
		rebuildAndSaveConfig(targetDir, latest);
	});
}
