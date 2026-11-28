export function skipStringOrComment(code: string, index: number) {
	const length = code.length;
	const character = code[index];
	if (character === '"' || character === "'" || character === "`") {
		const quote = character;
		index++;
		while (index < length) {
			if (code[index] === "\\") {
				index += 2;
				continue;
			}
			if (code[index] === quote) return index + 1;
			index++;
		}
		return length;
	}
	const isComment = character === "-" && code[index + 1] === "-";
	const opening = isComment ? index + 2 : index;
	if (code[opening] === "[") {
		let cursor = opening + 1;
		while (code[cursor] === "=") cursor++;
		if (code[cursor] === "[") {
			const closing = "]" + "=".repeat(cursor - opening - 1) + "]";
			const end = code.indexOf(closing, cursor + 1);
			return end === -1 ? length : end + closing.length;
		}
	}
	if (isComment) {
		const newline = code.indexOf("\n", opening);
		return newline === -1 ? length : newline;
	}
	return index;
}

export function stripLuaSource(code: string, mode: "strip-comments" | "mask-for-scan"): string {
	const maskForScan = mode === "mask-for-scan";
	const spanPattern = maskForScan ? /[^\r\n]/g : /[^\r\n]+/g;
	const parts: string[] = [];
	let copyFrom = 0;
	for (let index = 0; index < code.length; index++) {
		const end = skipStringOrComment(code, index);
		if (end === index) continue;
		const comment = code.startsWith("--", index);
		if (comment || maskForScan) {
			parts.push(code.slice(copyFrom, index));
			const span = code.slice(index, end);
			parts.push(span.replace(spanPattern, " "));
			copyFrom = end;
		}
		index = end - 1;
	}
	parts.push(code.slice(copyFrom));
	const result = parts.join("");
	return maskForScan ? result : result.trim();
}

export function mapLuaCode(source: string, transform: (code: string, offset: number) => string): string {
	const parts: string[] = [];
	let start = 0;
	for (let i = 0; i < source.length; i++) {
		const end = skipStringOrComment(source, i);
		if (end === i) continue;
		parts.push(transform(source.slice(start, i), start), source.slice(i, end));
		start = end;
		i = end - 1;
	}
	parts.push(transform(source.slice(start), start));
	return parts.join("");
}
