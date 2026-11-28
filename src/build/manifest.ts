import { log } from "../cli/log";
import fs from "node:fs";
import path from "node:path";
import { writeIfChanged } from "../project/config";
import { skipStringOrComment, stripLuaSource } from "../lua/source";

function findClosingBrace(content: string, openBraceIndex: number) {
	let depth = 0;
	for (let i = openBraceIndex; i < content.length; i++) {
		if (content[i] === "{") depth++;
		if (content[i] === "}" && --depth === 0) return i;
	}

	return -1;
}

function* pluralBlocks(content: string, keywordPlural: string) {
	const pluralRegex = new RegExp("^[ \\t]*" + keywordPlural + "\\s*\\{", "gm");
	const maskedSource = stripLuaSource(content, "mask-for-scan");
	for (const match of maskedSource.matchAll(pluralRegex)) {
		const blockStart = match.index;
		const openBrace = blockStart + match[0].length - 1;
		const blockEnd = findClosingBrace(maskedSource, openBrace);
		if (blockEnd !== -1) yield { openBrace, blockStart, blockContent: content.slice(blockStart, blockEnd + 1) };
	}
}

function skipTrivia(block: string, i: number) {
	while (i < block.length) {
		if (/\s/.test(block[i])) i++;
		else if (block.startsWith("--", i)) i = skipStringOrComment(block, i);
		else break;
	}
	return i;
}

function* managedEntries(block: string, openBrace: number, file: string) {
	let depth = 0;
	let blocks = 0;
	let fieldStart = true;
	const word = /[a-zA-Z_][a-zA-Z0-9_]*/y;
	for (let i = openBrace + 1; i < block.length; ) {
		i = skipTrivia(block, i);
		if (i >= block.length) break;
		const token = block[i];
		const end = skipStringOrComment(block, i);
		if (end > i) {
			if (fieldStart && (token === "'" || token === '"') && block.slice(i + 1, end - 1) === file) {
				const next = skipTrivia(block, end);
				if (block[next] === "}" || block[next] === "," || block[next] === ";") {
					yield { start: i, end, next };
				}
			}
			fieldStart = false;
			i = end;
			continue;
		}
		word.lastIndex = i;
		const identifier = word.exec(block)?.[0];
		if (identifier === "function" || identifier === "do" || identifier === "if" || identifier === "repeat") blocks++;
		else if (identifier === "end" || identifier === "until") blocks--;
		if (token === "{" || token === "(" || token === "[") depth++;
		else if (token === "}" || token === ")" || token === "]") depth--;
		fieldStart = depth === 0 && blocks === 0 && (token === "," || token === ";");
		i += identifier?.length ?? 1;
	}
}

function findDirective(content: string, expression: RegExp): RegExpExecArray | undefined {
	const maskedSource = stripLuaSource(content, "mask-for-scan");
	for (const match of content.matchAll(expression)) {
		if (maskedSource.slice(match.index, match.index + match[0].length).trim()) return match;
	}
}

export function prepareManifest(
	targetDir: string,
	hasClient: boolean,
	hasServer: boolean,
	hasShared: boolean,
	isIndividual = false,
): (() => void) | undefined {
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
		log(`! No fxmanifest.lua or __resource.lua found. Skipping manifest injection.`, "yellow");
		return;
	}

	let content = fs.readFileSync(manifestPath, "utf8");
	let injected = false;
	const newline = content.includes("\r\n") ? "\r\n" : "\n";

	const injectBlock = (type: string, entryPath: string) => {
		const keywordMatch = type.replace("_scripts", "_script").replace("files", "file");
		const entry = `'${entryPath}'`;
		const singularPattern = new RegExp(`^[ \\t]*${keywordMatch}(?:[ \\t]+(?=['"])|[ \\t]*\\()`, "gm");
		const firstSingular = findDirective(content, singularPattern);
		const [firstPlural] = pluralBlocks(content, type);
		const keepAt = firstSingular && (!firstPlural || firstSingular.index < firstPlural.blockStart) ? firstSingular.index : undefined;
		if (removeSingular(keywordMatch, entryPath, keepAt)) {
			removePlural(type, entryPath);
			return;
		}

		const [block] = pluralBlocks(content, type);
		const singular = findDirective(content, singularPattern);
		if (singular && (!block || singular.index < block.blockStart)) {
			removePlural(type, entryPath);
			const line = type === "escrow_ignore" ? type + " { " + entry + " }" : keywordMatch + " " + entry;
			content = content.slice(0, singular.index) + line + "\n" + content.slice(singular.index);
			injected = true;
			return;
		}
		if (block) {
			const first = skipTrivia(content, block.openBrace + 1);
			const [existing] = managedEntries(block.blockContent, block.openBrace - block.blockStart, entryPath);
			const alreadyFirst = existing && block.blockStart + existing.start === first;
			removePlural(type, entryPath, alreadyFirst ? first : undefined);
			if (alreadyFirst) return;
			const { openBrace } = block;
			content = content.substring(0, openBrace + 1) + `\n    ${entry},` + content.substring(openBrace + 1);
			injected = true;
			return;
		}

		content += `\n\n${type} {\n    ${entry}\n}`;
		injected = true;
	};

	const removeSingular = (keyword: string, entryPath: string, keepAt?: number) => {
		const escaped = entryPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
		const expression = new RegExp(
			`^[ \\t]*${keyword}(?:[ \\t]+(['"])${escaped}\\1|[ \\t]*\\([ \\t]*(['"])${escaped}\\2[ \\t]*\\))[ \\t]*;?`,
			"gm",
		);
		const maskedSource = stripLuaSource(content, "mask-for-scan");
		const matches = [...content.matchAll(expression)].filter((match) =>
			maskedSource.slice(match.index, match.index + match[0].length).trim(),
		);
		for (const match of matches.filter((entry) => entry.index !== keepAt).reverse()) {
			content = content.slice(0, match.index) + content.slice(match.index + match[0].length);
			injected = true;
		}
		return matches.some((entry) => entry.index === keepAt);
	};

	const removePlural = (type: string, entryPath: string, keepAt?: number) => {
		for (const block of [...pluralBlocks(content, type)].reverse()) {
			const entries = [...managedEntries(block.blockContent, block.openBrace - block.blockStart, entryPath)];
			for (const { start, end, next } of entries.reverse()) {
				const offset = block.blockStart;
				if (offset + start === keepAt) continue;
				const trivia = block.blockContent.slice(end, next);
				const hasSeparator = block.blockContent[next] !== "}";
				const suffix = offset + (hasSeparator ? next + 1 : end);
				content = content.slice(0, offset + start) + (hasSeparator && trivia.trim() ? trivia : "") + content.slice(suffix);
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

	if (injected)
		return () => {
			writeIfChanged(manifestPath, newline === "\r\n" ? content.replace(/\r?\n/g, "\r\n") : content);
			log(`✓ Updated manifest.`, "green");
		};
}
