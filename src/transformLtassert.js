function isIdentChar(c) {
	return /[a-zA-Z0-9_]/.test(c);
}

function isWordBoundary(code, index, wordLen) {
	const before = index > 0 ? code[index - 1] : "";
	const after = index + wordLen < code.length ? code[index + wordLen] : "";
	if (before && isIdentChar(before)) return false;
	if (after && isIdentChar(after)) return false;
	return true;
}

function skipStringOrComment(code, i, len) {
	const c = code[i];
	if (c === '"' || c === "'") {
		const quote = c;
		i++;
		while (i < len) {
			if (code[i] === "\\") {
				i += 2;
				continue;
			}
			if (code[i] === quote) return i + 1;
			i++;
		}
		return len;
	}
	if (c === "[") {
		let j = i + 1;
		let equalsCount = 0;
		while (j < len && code[j] === "=") {
			equalsCount++;
			j++;
		}
		if (j < len && code[j] === "[") {
			const endToken = "]" + "=".repeat(equalsCount) + "]";
			const endIndex = code.indexOf(endToken, j + 1);
			return endIndex === -1 ? len : endIndex + endToken.length;
		}
	}
	if (c === "-" && i + 1 < len && code[i + 1] === "-") {
		let j = i + 2;
		if (j < len && code[j] === "[") {
			let k = j + 1;
			let equalsCount = 0;
			while (k < len && code[k] === "=") {
				equalsCount++;
				k++;
			}
			if (k < len && code[k] === "[") {
				const endToken = "]" + "=".repeat(equalsCount) + "]";
				const endIndex = code.indexOf(endToken, k + 1);
				return endIndex === -1 ? len : endIndex + endToken.length;
			}
		}
		const endIndex = code.indexOf("\n", j);
		return endIndex === -1 ? len : endIndex;
	}
	return i;
}

function parseBalancedParens(code, openIndex, len) {
	let depth = 0;
	let i = openIndex;
	let inString = false;
	let stringChar = "";
	while (i < len) {
		const c = code[i];
		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
				i++;
				continue;
			}
			if (c === "[") {
				const next = skipStringOrComment(code, i, len);
				if (next > i + 1) {
					i = next;
					continue;
				}
			}
			if (c === "(") depth++;
			else if (c === ")") {
				depth--;
				if (depth === 0) return i + 1;
			}
		} else {
			if (c === "\\" && stringChar !== "]") {
				i += 2;
				continue;
			}
			if (c === stringChar) inString = false;
		}
		i++;
	}
	return -1;
}

function getLineStart(code, index) {
	let start = index;
	while (start > 0 && code[start - 1] !== "\n") start--;
	return start;
}

function getLineEnd(code, index, len) {
	let end = index;
	while (end < len && code[end] !== "\n") end++;
	return end;
}

function isFunctionLtassertDecl(code, ltassertIndex) {
	const lineStart = getLineStart(code, ltassertIndex);
	const before = code.substring(lineStart, ltassertIndex);
	return /\bfunction\s*$/.test(before);
}

function isAlreadyWrapped(code, ltassertIndex) {
	const lineStart = getLineStart(code, ltassertIndex);
	const before = code.substring(lineStart, ltassertIndex);
	return /\bif\s+not\s+$/.test(before);
}

function isStatementLevel(code, callEnd, len) {
	let i = callEnd;
	while (i < len && (code[i] === " " || code[i] === "\t")) i++;
	if (i < len && code[i] === ";") i++;
	while (i < len && (code[i] === " " || code[i] === "\t")) i++;
	return i >= len || code[i] === "\n" || code[i] === "\r";
}

function transformLtassertStatements(source) {
	if (!source) return source;
	const len = source.length;
	let out = "";
	let i = 0;
	const word = "ltassert";

	while (i < len) {
		const skipped = skipStringOrComment(source, i, len);
		if (skipped > i) {
			out += source.substring(i, skipped);
			i = skipped;
			continue;
		}

		if (
			source.startsWith(word, i) &&
			isWordBoundary(source, i, word.length) &&
			i + word.length < len &&
			source[i + word.length] === "("
		) {
			if (!isFunctionLtassertDecl(source, i) && !isAlreadyWrapped(source, i)) {
				const openParen = i + word.length;
				const callEnd = parseBalancedParens(source, openParen, len);
				if (callEnd !== -1 && isStatementLevel(source, callEnd, len)) {
					const args = source.substring(openParen + 1, callEnd - 1);
					const indent = source.substring(getLineStart(source, i), i);
					const replacement = `${indent}if not ltassert(${args}) then return false end`;
					out += replacement;
					i = callEnd;
					while (i < len && (source[i] === " " || source[i] === "\t")) i++;
					if (i < len && source[i] === ";") i++;
					continue;
				}
			}
		}

		out += source[i];
		i++;
	}

	return out;
}

module.exports = { transformLtassertStatements };
