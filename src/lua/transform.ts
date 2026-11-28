import { skipStringOrComment } from "./source";

function isIdentChar(c: string) {
	return /[a-zA-Z0-9_]/.test(c);
}

function isWordBoundary(code: string, index: number, wordLen: number) {
	const before = index > 0 ? code[index - 1] : "";
	const after = index + wordLen < code.length ? code[index + wordLen] : "";
	if (before && isIdentChar(before)) return false;
	if (after && isIdentChar(after)) return false;
	return true;
}

function parseBalancedParens(code: string, openIndex: number, len: number) {
	let depth = 0;
	for (let i = openIndex; i < len; i++) {
		const skipped = skipStringOrComment(code, i);
		if (skipped > i) {
			i = skipped - 1;
			continue;
		}
		if (code[i] === "(") depth++;
		if (code[i] === ")" && --depth === 0) return i + 1;
	}
	return -1;
}

function getLineStart(code: string, index: number) {
	let start = index;
	while (start > 0 && code[start - 1] !== "\n") start--;
	return start;
}

function isStatementLevel(code: string, callEnd: number, len: number) {
	let i = callEnd;
	while (i < len && (code[i] === " " || code[i] === "\t")) i++;
	if (i >= len || code[i] === ";") return true;
	if (code[i] !== "\n" && code[i] !== "\r" && !code.startsWith("--", i)) return false;
	while (i < len) {
		if (/\s/.test(code[i])) i++;
		else if (code.startsWith("--", i)) i = skipStringOrComment(code, i);
		else break;
	}
	return i >= len || !"([.{:'\"".includes(code[i]);
}

export function transformLtassertStatements(source: string) {
	if (!source) return source;
	const len = source.length;
	let out = "";
	let i = 0;
	const word = "ltassert";
	let expressionDepth = 0;
	const blocks: (number | null)[] = [];
	const keyword = /(?:function|if|do|end)\b/y;
	let previousTokenEnd = 0;

	while (i < len) {
		const skipped = skipStringOrComment(source, i);
		if (skipped > i) {
			if (!source.startsWith("--", i)) previousTokenEnd = skipped;
			out += source.substring(i, skipped);
			i = skipped;
			continue;
		}

		if (source.startsWith(word, i) && isWordBoundary(source, i, word.length)) {
			const bodyDepth = [...blocks].reverse().find((block) => block !== null) ?? 0;
			if (
				expressionDepth === bodyDepth &&
				/^[ \t]*$/.test(source.slice(getLineStart(source, i), i)) &&
				!/(?:\b(?:return|and|or|not|if|elseif|while|until|in)|[=+*/%<>~^|&.,:#-])$/.test(
					source.slice(Math.max(0, previousTokenEnd - 16), previousTokenEnd),
				)
			) {
				let openParen = i + word.length;
				while (source[openParen] === " " || source[openParen] === "\t") openParen++;
				const callEnd = source[openParen] === "(" ? parseBalancedParens(source, openParen, len) : -1;
				if (callEnd !== -1 && isStatementLevel(source, callEnd, len)) {
					const args = source.substring(openParen + 1, callEnd - 1);
					const replacement = `if not ltassert(${args}) then return false end`;
					out += replacement;
					i = callEnd;
					previousTokenEnd = callEnd;
					while (i < len && (source[i] === " " || source[i] === "\t")) i++;
					if (i < len && source[i] === ";") i++;
					continue;
				}
			}
		}
		if (!i || !isIdentChar(source[i - 1])) {
			keyword.lastIndex = i;
			const block = keyword.exec(source)?.[0];
			if (block === "end") blocks.pop();
			else if (block) blocks.push(block === "function" ? expressionDepth : null);
		}

		if ("({[".includes(source[i])) expressionDepth++;
		if (")}]".includes(source[i])) expressionDepth--;
		if (!/\s/.test(source[i])) previousTokenEnd = i + 1;
		out += source[i];
		i++;
	}

	return out;
}
