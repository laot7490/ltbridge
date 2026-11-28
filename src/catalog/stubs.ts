import { publicExportNames } from "./exports";
import { skipStringOrComment, stripLuaSource } from "../lua/source";
import type { Side, Stub, StubMetadata } from "./database";

function extractTableKeys(source: string, tableName: string) {
	const declaration = new RegExp("\\b" + tableName + "\\s*=\\s*\\{").exec(stripLuaSource(source, "mask-for-scan"));
	if (!declaration) return [];
	const keys: string[] = [];
	let fieldStart = declaration.index + declaration[0].length;
	let depth = 0;

	for (let cursor = fieldStart; cursor < source.length; cursor++) {
		const next = skipStringOrComment(source, cursor);
		if (next > cursor) {
			cursor = next - 1;
			continue;
		}
		const token = source[cursor];
		if (depth === 0 && (token === "," || token === ";" || token === "}")) {
			const field = source.slice(fieldStart, cursor).replace(/^(?:\s|--[^\n]*\n)*/, "");
			const match = /^(?:\[(['"])(.*?)\1\]\s*=|(['"])(.*?)\3|([a-zA-Z_]\w*))/.exec(field);
			const key = match?.[2] ?? match?.[4] ?? match?.[5];
			if (key) keys.push(key);
			if (token === "}") return keys;
			fieldStart = cursor + 1;
		} else if ("({[".includes(token)) depth++;
		else if (")}]".includes(token)) depth--;
	}
	return [];
}

export function extractStubs(code: string, ns: string | null, context: Side) {
	const stubs: Stub[] = [];
	const funcWithEmmyRegex =
		/(^|\n)((?:^[ \t]*---.*(?:\r?\n|$))*)[ \t]*function\s+(?:LT\.[a-zA-Z0-9_.]+\.)?([a-zA-Z0-9_]+)\s*\(([^)]*)\)/gm;
	let match;
	while ((match = funcWithEmmyRegex.exec(code)) !== null) {
		const rawBlock = match[2] ? match[2].trim() : "";
		const funcName = match[3];
		const origParams = match[4];
		if (!rawBlock) continue;

		const metadata: StubMetadata = {};
		const ltbridgeRegex = /^[ \t]*---[ \t]*@ltbridge[ \t]+([a-zA-Z0-9]+)(?:[.: \t]+([a-zA-Z0-9_]+))?/gm;
		let ltMatch;
		while ((ltMatch = ltbridgeRegex.exec(rawBlock)) !== null) {
			const dir = ltMatch[1];
			const arg = ltMatch[2];
			if (dir === "export" || dir === "convert") metadata.export = arg;
			if (dir === "global") metadata.global = arg || true;
			if (dir === "internal" || dir === "private") metadata.internal = true;
			if (dir === "alias" && arg) {
				metadata.alias = metadata.alias || [];
				metadata.alias.push(arg);
			}
		}

		let commentBlock = rawBlock;
		const dynRegex = /^[ \t]*---[ \t]*@ltbridge[ \t]+(params?|returns?)[.: \t]+([a-zA-Z0-9_]+)(?:[.: \t]+([a-zA-Z0-9_]+))?/gm;
		commentBlock = commentBlock.replace(dynRegex, (_match, type, tableName, extraArg) => {
			const keys = extractTableKeys(code, tableName);
			if (keys.length === 0) return `--- @${type.startsWith("param") ? "param" : "return"} any`;
			let unionStr = keys.map((k) => `'${k}'`).join("|");
			if (type.startsWith("param")) return `--- @param ${extraArg || "unnamed"} ${unionStr}`;
			if (extraArg) unionStr += `|${extraArg}`;
			return `--- @return ${unionStr}`;
		});
		commentBlock = commentBlock.replace(/^[ \t]*---[ \t]*@ltbridge.*(?:\r?\n|$)/gm, "").trim();

		const category = ns ? ns.toUpperCase() : "GENERAL";
		const header = `--- **\`${category}\` \`${context.toUpperCase()}\`**`;
		const formsToExport = publicExportNames(funcName, ns, metadata);

		let formsCode = "";
		for (const form of formsToExport) {
			formsCode += `${header}\n${commentBlock}\nfunction LT.${form}(${origParams}) end\n\n`;
		}
		stubs.push({ funcName, metadata, stubCode: formsCode.trim() });
	}
	return stubs;
}

const CLASS_LINE_RE = /^[ \t]*---[ \t]*@class[ \t]+([a-zA-Z_][a-zA-Z0-9_.]*)/;
const CLASS_RELATED_LINE_RE = /^[ \t]*---[ \t]*@(field|extends|generic)\b/;

export function extractEmmyClasses(code: string) {
	if (!code) return [];
	const lines = code.split(/\r?\n/);
	const types = [];
	let i = 0;
	while (i < lines.length) {
		const classMatch = CLASS_LINE_RE.exec(lines[i]);
		if (!classMatch) {
			i++;
			continue;
		}
		const className = classMatch[1];
		const blockLines = [lines[i]];
		i++;
		while (i < lines.length) {
			const line = lines[i];
			if (CLASS_RELATED_LINE_RE.test(line)) {
				blockLines.push(line);
				i++;
				continue;
			}
			break;
		}
		types.push({ className, code: blockLines.join("\n") });
	}
	return types;
}
