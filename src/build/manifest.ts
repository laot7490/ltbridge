import fs from "node:fs";
import path from "node:path";
import { writeIfChanged } from "../project/config";
import { skipStringOrComment, stripLuaForScan } from "../lua/source";

function findBlockEnd(content: string, openBraceIndex: number) {
	let depth = 0;
	for (let i = openBraceIndex; i < content.length; i++) {
		const end = skipStringOrComment(content, i);
		if (end > i) {
			i = end - 1;
			continue;
		}
		if (content[i] === "{") depth++;
		if (content[i] === "}" && --depth === 0) return i;
	}

	return -1;
}

function* pluralBlocks(content: string, keywordPlural: string) {
	const pluralRegex = new RegExp("^[ \\t]*" + keywordPlural + "\\s*\\{", "gm");
	for (const match of stripLuaForScan(content).matchAll(pluralRegex)) {
		const blockStart = match.index;
		const openBrace = blockStart + match[0].length - 1;
		const blockEnd = findBlockEnd(content, openBrace);
		if (blockEnd !== -1) yield { openBrace, blockStart, blockContent: content.slice(blockStart, blockEnd + 1) };
	}
}

function entrySpan(block: string, file: string): [number, number] | undefined {
	for (let i = 0; i < block.length; i++) {
		const end = skipStringOrComment(block, i);
		if (end === i) continue;
		if ((block[i] === "'" || block[i] === '"') && block.slice(i + 1, end - 1) === file) return [i, end];
		i = end - 1;
	}
}

function findDirective(content: string, expression: RegExp): RegExpExecArray | undefined {
	const visible = stripLuaForScan(content);
	for (const match of content.matchAll(expression)) {
		if (visible.slice(match.index, match.index + match[0].length).trim()) return match;
	}
}

export function prepareManifest(targetDir: string, hasClient: boolean, hasServer: boolean, hasShared: boolean, isIndividual = false): (() => void) | undefined {
	const manifestNames = ["fxmanifest.lua", "__resource.lua"];
	let manifestPath = null;

	for (const name of manifestNames) {
		const checkPath = path.join(targetDir, name);
		if (fs.existsSync(checkPath)) {
			manifestPath = checkPath;
			break;
		}
	}

	if (!manifestPath) {
		console.log(`\x1b[33m! No fxmanifest.lua or __resource.lua found. Skipping manifest injection.\x1b[0m`);
		return;
	}

	let content = fs.readFileSync(manifestPath, "utf8");
	let injected = false;
	const newline = content.includes("\r\n") ? "\r\n" : "\n";

	const injectBlock = (type: string, entryPath: string) => {
		const keywordMatch = type.replace("_scripts", "_script").replace("files", "file");
		const keywordPlural = type;
		const entry = `'${entryPath}'`;
		const singularPattern = new RegExp(`^[ \\t]*${keywordMatch}(?:[ \\t]+(?=['"])|[ \\t]*\\()`, "gm");
		const firstSingular = findDirective(content, singularPattern);
		const [firstPlural] = pluralBlocks(content, type);
		const keepAt = firstSingular && (!firstPlural || firstSingular.index < firstPlural.blockStart) ? firstSingular.index : undefined;
		if (removeSingular(keywordMatch, entryPath, keepAt)) {
			removePlural(type, entryPath);
			return;
		}

		const [block] = pluralBlocks(content, keywordPlural);
		const singular = findDirective(content, singularPattern);
		if (singular && (!block || singular.index < block.blockStart)) {
			removePlural(type, entryPath);
			const line = type === "escrow_ignore" ? type + " { " + entry + " }" : keywordMatch + " " + entry;
			content = content.slice(0, singular.index) + line + "\n" + content.slice(singular.index);
			injected = true;
			return;
		}
		if (block) {
			const existing = entrySpan(block.blockContent, entryPath);
			let first = block.openBrace + 1;
			while (first < content.length) {
				if (/\s/.test(content[first])) first++;
				else if (content.startsWith("--", first)) first = skipStringOrComment(content, first);
				else break;
			}
			const alreadyFirst = existing && block.blockStart + existing[0] === first;
			removePlural(type, entryPath, alreadyFirst ? first : undefined);
			if (alreadyFirst) return;
			const { openBrace } = block;
			content =
				content.substring(0, openBrace + 1) +
				`\n    ${entry},` +
				content.substring(openBrace + 1);
			injected = true;
			return;
		}

		content += `\n\n${keywordPlural} {\n    ${entry}\n}`;
		injected = true;
	};

	const removeSingular = (keyword: string, entryPath: string, keepAt?: number) => {
		const escaped = entryPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
		const expression = new RegExp(`^[ \\t]*${keyword}(?:[ \\t]+(['"])${escaped}\\1|[ \\t]*\\([ \\t]*(['"])${escaped}\\2[ \\t]*\\))[ \\t]*;?`, "gm");
		const visible = stripLuaForScan(content);
		const matches = [...content.matchAll(expression)].filter((match) => visible.slice(match.index, match.index + match[0].length).trim());
		for (const match of matches.filter((entry) => entry.index !== keepAt).reverse()) {
			content = content.slice(0, match.index) + content.slice(match.index + match[0].length);
			injected = true;
		}
		return matches.some((entry) => entry.index === keepAt);
	};

	const removePlural = (type: string, entryPath: string, keepAt?: number) => {
		for (const block of [...pluralBlocks(content, type)].reverse()) {
			const entries: [number, number][] = [];
			let offset = 0;
			let entry;
			while ((entry = entrySpan(block.blockContent.slice(offset), entryPath))) {
				const start = block.blockStart + offset + entry[0];
				offset += entry[1];
				if (start !== keepAt) entries.push([start, block.blockStart + offset]);
			}
			for (const [start, end] of entries.reverse()) {
				const separator = /^[ \t]*[,;]/.exec(content.slice(end));
				content = content.slice(0, start) + content.slice(end + (separator?.[0].length ?? 0));
				injected = true;
			}
		}
	};

	const removeBlock = (type: string, file: string) => {
		const entryPath = `ltbridge/modules/${file}`;
		removePlural(type, entryPath);
		removeSingular(type.replace("_scripts", "_script").replace("files", "file"), entryPath);
	};

	const sharedFile = "shared.lua";
	const clientFile = "client.lua";
	const serverFile = "server.lua";

	if (hasShared) injectBlock("shared_scripts", "ltbridge/modules/" + sharedFile);
	else removeBlock("shared_scripts", sharedFile);

	if (hasClient) injectBlock("client_scripts", "ltbridge/modules/" + clientFile);
	else removeBlock("client_scripts", clientFile);

	if (hasServer) injectBlock("server_scripts", "ltbridge/modules/" + serverFile);
	else removeBlock("server_scripts", serverFile);

	injectBlock("escrow_ignore", "ltbridge/**/*.lua");

	if (isIndividual && (hasShared || hasClient)) {
		injectBlock("files", "ltbridge/modules/imports/**/*.lua");
	} else {
		removeBlock("files", "imports/**/*.lua");
	}

	if (injected) return () => {
		writeIfChanged(manifestPath, newline === "\r\n" ? content.replace(/\r?\n/g, "\r\n") : content);
		console.log(`\x1b[32m✓ Updated manifest.\x1b[0m`);
	};
}


export function updateManifest(...args: Parameters<typeof prepareManifest>) {
	prepareManifest(...args)?.();
}
