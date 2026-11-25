export function skipStringOrComment(code: string, i: number, len = code.length) {
	const c = code[i];
	if (c === '"' || c === "'" || c === "`") {
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

function strip(code: string, maskStrings: boolean): string {
	const parts: string[] = [];
	let start = 0;
	for (let i = 0; i < code.length; i++) {
		const end = skipStringOrComment(code, i);
		if (end === i) continue;
		const comment = code.startsWith("--", i);
		if (comment || maskStrings) {
			parts.push(code.slice(start, i));
			const span = code.slice(i, end);
			parts.push(maskStrings ? span.replace(/[^\r\n]/g, " ") : span.replace(/[^\r\n]+/g, " "));
			start = end;
		}
		i = end - 1;
	}
	parts.push(code.slice(start));
	return parts.join("");
}

export function stripLuaComments(code: string): string {
	return strip(code, false).trim();
}

export function stripLuaForScan(code: string): string {
	return strip(code, true);
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
