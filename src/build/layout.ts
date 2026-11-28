import { version } from "../../package.json";
import { SIDES, type Side } from "../catalog/database";

export interface RenderedChunk {
	moduleId: string;
	side: Side;
	content: string;
}

export function formatBuildOutputs(chunks: RenderedChunk[], requiredTables: Record<Side, Set<string>>, individual: boolean) {
	const outputs = new Map<string, string>();
	const emitted = new Set<Side>();
	const bundles = { shared: "", client: "", server: "" };
	const loaders: Record<Side, string[]> = { shared: [], client: [], server: [] };

	const getBundleHeader = (type: string) =>
		`--[[\n * @license LT Bridge\n * ${type.toLowerCase()}.lua\n *\n * Copyright (c) LT Scripts.\n *\n * This source code is licensed under the MIT license found in the\n * LICENSE file in the root directory of this source tree.\n]]\n\n`;

	const generateLoader = (sideName: string, items: string[]) => {
		return `-- LTBridge Auto-Generated ${sideName} Loader

local RESOURCE <const> = GetCurrentResourceName()
local BASE_PATH <const> = "ltbridge/modules/imports/"

local modules = {
${items.join(",\n")}
}

local function loadModule(path)
    local fullPath = BASE_PATH .. path
    local content = LoadResourceFile(RESOURCE, fullPath)
    if not content then
        return print(("^6[LTBridge ${version}] ^1ERROR: Module file not found: %s^7"):format(path))
    end
    local chunk, err = load(content, ("@@%s/%s"):format(RESOURCE, fullPath))
    if not chunk then
        return print(("^6[LTBridge ${version}] ^1ERROR: Syntax error in module: %s\\n%s^7"):format(fullPath, err))
    end
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        print(("^6[LTBridge ${version}] ^1ERROR: Runtime error in module: %s\\n%s^7"):format(fullPath, runtimeErr))
    end
end

for i = 1, #modules do
    loadModule(modules[i])
end
`;
	};

	for (const { moduleId, side, content } of chunks) {
		emitted.add(side);
		if (individual) {
			const file = getIndividualPath(moduleId, side).replaceAll("\\", "/");
			outputs.set("modules/" + file, getBundleHeader(side) + "--- @diagnostic disable\n" + content);
			loaders[side].push(`    "${file.slice("imports/".length)}"`);
		} else {
			bundles[side] += content + "\n";
		}
	}

	for (const side of SIDES) {
		if (!emitted.has(side)) continue;
		const file = `modules/${side}.lua`;
		if (individual) {
			const title = side[0].toUpperCase() + side.slice(1);
			outputs.set(file, generateLoader(title, loaders[side]));
		} else {
			const tables = requiredTables[side];
			const init = "LT = LT or {}\n" + [...tables].join("\n") + (tables.size ? "\n\n" : "\n");
			outputs.set(file, getBundleHeader(side) + "--- @diagnostic disable\n" + init + bundles[side]);
		}
	}

	return { outputs, hasClient: emitted.has("client"), hasServer: emitted.has("server"), hasShared: emitted.has("shared") };
}

function getIndividualPath(modName: string, type: Side) {
	const modParts = modName.split("/");
	let category = "uncategorized";
	let name = modName;
	if (modName === "__init__") {
		category = "Core";
		name = "init";
	} else if (modParts.length > 1) {
		category = modParts.slice(0, -1).join("/").replace(/^@/, "");
		name = modParts[modParts.length - 1];
	} else if (modName.startsWith("@")) {
		category = modName.replace(/^@/, "");
		name = "init";
	} else {
		name = modName.replace(/^@/, "");
	}
	return name === "init" ? `imports/${category}/${type}.lua` : `imports/${category}/${name}/${type}.lua`;
}
