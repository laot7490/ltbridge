function stripLuaComments(code) {
	let out = "";
	let i = 0;
	const len = code.length;
	let inString = false;
	let stringChar = "";

	while (i < len) {
		let c = code[i];

		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
				out += c;
				i++;
				continue;
			}

			if (c === "[") {
				let j = i + 1;
				let equalsCount = 0;
				while (j < len && code[j] === "=") {
					equalsCount++;
					j++;
				}
				if (j < len && code[j] === "[") {
					inString = true;
					stringChar = "]";
					out += code.substring(i, j + 1);
					i = j + 1;
					continue;
				}
			}

			if (c === "-" && i + 1 < len && code[i + 1] === "-") {
				let j = i + 2;
				let isBlockComment = false;

				if (j < len && code[j] === "[") {
					let k = j + 1;
					let equalsCount = 0;
					while (k < len && code[k] === "=") {
						equalsCount++;
						k++;
					}
					if (k < len && code[k] === "[") {
						isBlockComment = true;
						let endToken = "]" + "=".repeat(equalsCount) + "]";
						let endIndex = code.indexOf(endToken, k + 1);
						if (endIndex === -1) endIndex = len;
						else endIndex += endToken.length;
						i = endIndex;
						continue;
					}
				}

				if (!isBlockComment) {
					let endIndex = code.indexOf("\n", j);
					if (endIndex === -1) endIndex = len;
					i = endIndex;
					continue;
				}
			}
		} else {
			if (c === "\\" && stringChar !== "]") {
				out += code.substring(i, i + 2);
				i += 2;
				continue;
			}
			if (c === stringChar) {
				if (stringChar === "]") {
					let j = i + 1;
					let equalsCount = 0;
					while (j < len && code[j] === "=") {
						equalsCount++;
						j++;
					}
					if (j < len && code[j] === "]") {
						inString = false;
						out += code.substring(i, j + 1);
						i = j + 1;
						continue;
					}
				} else {
					inString = false;
				}
			}
		}

		out += c;
		i++;
	}

	return out.replace(/^\s*[\r\n]/gm, "\n").trim();
}

function stripLuaForScan(code) {
	let out = "";
	let i = 0;
	const len = code.length;
	let inString = false;
	let stringChar = "";

	while (i < len) {
		let c = code[i];

		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
				out += " ";
				i++;
				continue;
			}

			if (c === "[") {
				let j = i + 1;
				let equalsCount = 0;
				while (j < len && code[j] === "=") {
					equalsCount++;
					j++;
				}
				if (j < len && code[j] === "[") {
					inString = true;
					stringChar = "]";
					out += " ";
					i = j + 1;
					continue;
				}
			}

			if (c === "-" && i + 1 < len && code[i + 1] === "-") {
				let j = i + 2;
				let isBlockComment = false;

				if (j < len && code[j] === "[") {
					let k = j + 1;
					let equalsCount = 0;
					while (k < len && code[k] === "=") {
						equalsCount++;
						k++;
					}
					if (k < len && code[k] === "[") {
						isBlockComment = true;
						let endToken = "]" + "=".repeat(equalsCount) + "]";
						let endIndex = code.indexOf(endToken, k + 1);
						if (endIndex === -1) endIndex = len;
						else endIndex += endToken.length;
						i = endIndex;
						continue;
					}
				}

				if (!isBlockComment) {
					let endIndex = code.indexOf("\n", j);
					if (endIndex === -1) endIndex = len;
					i = endIndex;
					continue;
				}
			}
		} else {
			if (c === "\\" && stringChar !== "]") {
				out += " ";
				i += 2;
				continue;
			}
			if (c === stringChar) {
				if (stringChar === "]") {
					let j = i + 1;
					let equalsCount = 0;
					while (j < len && code[j] === "=") {
						equalsCount++;
						j++;
					}
					if (j < len && code[j] === "]") {
						inString = false;
						out += " ";
						i = j + 1;
						continue;
					}
					out += " ";
					i++;
					continue;
				} else {
					inString = false;
					out += " ";
					i++;
					continue;
				}
			}
			out += " ";
			i++;
			continue;
		}

		out += c;
		i++;
	}

	return out;
}

module.exports = { stripLuaComments, stripLuaForScan };
