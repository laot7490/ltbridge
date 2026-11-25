import prompts from "prompts";
import { readProjectConfig, saveConfig, withProjectWrite } from "../project/config";
import { rebuildBundle } from "../build/index";
interface ModuleEntry { mod: string; name: string }
import { getModuleRegistry, isPublicModule } from "../catalog/database";
import { resolveDependencies } from "../catalog/resolve";

function getVisibleModules() {
	return Object.keys(getModuleRegistry()).filter(isPublicModule);
}

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

function getDependencySets(configModules: string[]) {
	const depsSet = new Set<string>();

	if (configModules && configModules.length > 0) {
		const { graph } = resolveDependencies(configModules);
		for (const deps of Object.values(graph)) {
			for (const d of deps) {
				depsSet.add(d);
			}
		}
	}

	return depsSet;
}

function getVisibleGroupModules(modsInGroup: ModuleEntry[], group: string) {
	const lastPart = group.split(" / ").pop();
	const initModName = "@" + lastPart;
	const filteredMods = modsInGroup.length > 1 ? modsInGroup.filter((m) => m.mod !== initModName) : modsInGroup;
	return filteredMods.sort((a, b) => a.name.localeCompare(b.name));
}


export async function interactiveSelect(targetDir: string) {
	const registry = getModuleRegistry();
	const allModules = getVisibleModules();

	const currentConfig = readProjectConfig(targetDir, true);

	if (!currentConfig) {
		console.log(`\x1b[31m✖ Not an LTBridge initialized directory. Run 'ltbridge init' first.\x1b[0m`);
		return;
	}

	const installed = new Set(currentConfig.modules);
	const depsSet = getDependencySets(currentConfig.modules || []);
	const groups = buildModuleGroups(allModules, registry);

	const choices: prompts.Choice[] = [];
	for (const group of Object.keys(groups).sort()) {
		choices.push({
			title: `\x1b[1m\x1b[36m--- ${group.toUpperCase()} ---\x1b[0m`,
			value: `__group_${group}__`,
			disabled: true,
		});

		const sortedMods = getVisibleGroupModules(groups[group], group);

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

	const selectableModules = new Set(choices.filter((choice) => !choice.disabled).map((choice) => choice.value));
	const selected = new Set<string>(response.selectedModules.filter((id: string) => selectableModules.has(id)));
	const finalSelection = currentConfig.modules.filter((id) => !selectableModules.has(id) || selected.has(id));
	for (const id of selected) if (!installed.has(id)) finalSelection.push(id);
	const toAdd = finalSelection.filter((m) => !installed.has(m));
	const toRemove = Array.from(installed).filter((m) => !finalSelection.includes(m));

	if (toAdd.length === 0 && toRemove.length === 0) {
		console.log(`\x1b[90mℹ No changes made to module selection.\x1b[0m`);
		return;
	}

	if (toAdd.length > 0) console.log(`\x1b[32m✓ Adding: ${toAdd.join(", ")}\x1b[0m`);
	if (toRemove.length > 0) console.log(`\x1b[33m- Removing: ${toRemove.join(", ")}\x1b[0m`);

	withProjectWrite(targetDir, () => {
		const latest = readProjectConfig(targetDir);
		if (JSON.stringify(latest) !== JSON.stringify(currentConfig)) throw new Error("LTBridge config changed during selection. Open the picker again.");
		latest.modules = finalSelection;
		rebuildBundle(targetDir, latest);
		saveConfig(targetDir, latest);
	});
}

