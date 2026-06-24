const fs = require("fs-extra");
const path = require("path");
const { applyBuildConstants } = require("../src/buildConstants");
const { transformLtassertStatements } = require("../src/transformLtassert");

const modulesDir = path.join(__dirname, "..", "modules");
const version = require("../package.json").version;
const distDir = path.join(__dirname, "..", "dist");

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

function extractTableKeys(source, tableName) {
	const cleanSource = stripLuaComments(source);
	const regex = new RegExp(`(?:local\\s+)?${tableName}\\s*=\\s*\\{`, "g");
	const match = regex.exec(cleanSource);
	if (!match) return [];

	let braceStart = match.index + match[0].length - 1;
	let i = braceStart + 1;
	const len = cleanSource.length;
	let depth = 1;
	let inString = false;
	let stringChar = "";
	let tableBodyEnd = i;

	while (tableBodyEnd < len && depth > 0) {
		let c = cleanSource[tableBodyEnd];
		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
			} else if (c === "[") {
				let j = tableBodyEnd + 1;
				while (j < len && cleanSource[j] === "=") j++;
				if (cleanSource[j] === "[") {
					inString = true;
					stringChar = "]";
					tableBodyEnd = j;
				} else if (c === "{") depth++;
			} else if (c === "{") depth++;
			else if (c === "}") depth--;
		} else {
			if (c === "\\" && stringChar !== "]") {
				tableBodyEnd++;
			} else if (c === stringChar) {
				if (stringChar === "]") {
					let j = tableBodyEnd + 1;
					while (j < len && cleanSource[j] === "=") j++;
					if (cleanSource[j] === "]") {
						inString = false;
						tableBodyEnd = j;
					}
				} else {
					inString = false;
				}
			}
		}
		if (depth > 0) tableBodyEnd++;
	}

	const tableBody = cleanSource.substring(i, tableBodyEnd);
	let k = 0;
	let keyBuffer = "";
	inString = false;
	depth = 0;
	const keys = [];

	while (k < tableBody.length) {
		let c = tableBody[k];
		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
				keyBuffer += c;
			} else if (c === "{") {
				depth++;
				keyBuffer += c;
			} else if (c === "}") {
				depth--;
				keyBuffer += c;
			} else if (c === "," && depth === 0) {
				let eqIdx = keyBuffer.indexOf("=");
				if (eqIdx !== -1) {
					let left = keyBuffer.substring(0, eqIdx).trim();
					let m = /(?:\[(['"])(.+?)\1\]|([a-zA-Z_][a-zA-Z0-9_]*))/.exec(left);
					if (m) keys.push(m[2] || m[3]);
				} else {
					let m = /(['"])(.+?)\1|([a-zA-Z_][a-zA-Z0-9_]*)/.exec(keyBuffer.trim());
					if (m) keys.push(m[2] || m[3]);
				}
				keyBuffer = "";
			} else {
				keyBuffer += c;
			}
		} else {
			keyBuffer += c;
			if (c === "\\" && stringChar !== "]") {
				k++;
				keyBuffer += tableBody[k];
			} else if (c === stringChar) inString = false;
		}
		k++;
	}

	if (keyBuffer.trim()) {
		let eqIdx = keyBuffer.indexOf("=");
		if (eqIdx !== -1) {
			let left = keyBuffer.substring(0, eqIdx).trim();
			let m = /(?:\[(['"])(.+?)\1\]|([a-zA-Z_][a-zA-Z0-9_]*))/.exec(left);
			if (m) keys.push(m[2] || m[3]);
		} else {
			let m = /(['"])(.+?)\1|([a-zA-Z_][a-zA-Z0-9_]*)/.exec(keyBuffer.trim());
			if (m) keys.push(m[2] || m[3]);
		}
	}
	return keys;
}

function extractStubs(code, ns, context) {
	const stubs = [];
	const funcWithEmmyRegex =
		/(^|\n)((?:^[ \t]*---.*(?:\r?\n|$))*)[ \t]*function\s+(?:LT\.[a-zA-Z0-9_.]+\.)?([a-zA-Z0-9_]+)\s*\(([^)]*)\)/gm;
	let match;
	while ((match = funcWithEmmyRegex.exec(code)) !== null) {
		const rawBlock = match[2] ? match[2].trim() : "";
		const funcName = match[3];
		const origParams = match[4];
		if (!rawBlock) continue;

		const metadata = {};
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
		commentBlock = commentBlock.replace(dynRegex, (m, type, tableName, extraArg) => {
			const keys = extractTableKeys(code, tableName);
			if (!keys || keys.length === 0) return `--- @${type.startsWith("param") ? "param" : "return"} any`;
			let unionStr = keys.map((k) => `'${k}'`).join("|");
			if (type.startsWith("param")) return `--- @param ${extraArg || "unnamed"} ${unionStr}`;
			if (extraArg) unionStr += `|${extraArg}`;
			return `--- @return ${unionStr}`;
		});
		commentBlock = commentBlock.replace(/^[ \t]*---[ \t]*@ltbridge.*(?:\r?\n|$)/gm, "").trim();

		const category = ns ? ns.toUpperCase() : "GENERAL";
		const header = `--- **\`${category}\` \`${context.toUpperCase()}\`**`;
		const prefixStr = ns ? `LT.${ns}.` : `LT.`;

		const formsToExport = [];
		if (metadata.export) {
			formsToExport.push(`${prefixStr}${metadata.export}`);
			if (metadata.global) {
				const gName = metadata.global === true ? metadata.export : metadata.global;
				formsToExport.push(`LT.${gName}`);
			}
		} else if (metadata.global) {
			const gName = metadata.global === true ? funcName : metadata.global;
			formsToExport.push(`LT.${gName}`);
		} else {
			formsToExport.push(ns ? `LT.${ns}.${funcName}` : `LT.${funcName}`);
		}
		if (metadata.alias) {
			metadata.alias.forEach((al) => formsToExport.push(`${prefixStr}${al}`));
		}

		let formsCode = "";
		for (const form of formsToExport) {
			formsCode += `${header}\n${commentBlock}\nfunction ${form}(${origParams}) end\n\n`;
		}
		stubs.push({ funcName, metadata, stubCode: formsCode.trim() });
	}
	return stubs;
}

const CLASS_LINE_RE = /^[ \t]*---[ \t]*@class[ \t]+([a-zA-Z_][a-zA-Z0-9_.]*)/;
const CLASS_RELATED_LINE_RE = /^[ \t]*---[ \t]*@(field|extends|generic)\b/;

function extractEmmyClasses(code) {
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
			if (/^[ \t]*---/.test(line)) break;
			if (line.trim().length > 0) break;
			break;
		}
		types.push({ className, code: blockLines.join("\n") });
	}
	return types;
}

function compile() {
	if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });

	const db = {
		version: version,
		modules: {},
		exportMap: {},
		registry: {},
	};

	function scan(currentPath) {
		if (!fs.existsSync(currentPath)) return;
		const items = fs.readdirSync(currentPath);

		let isModule = items.some((i) => i === "client.lua" || i === "server.lua" || i === "shared.lua" || i === "module.json");

		if (isModule) {
			const relative = path.relative(modulesDir, currentPath);
			let name = relative.replace(/\\/g, "/");
			if (name.endsWith("/__init__")) name = name.substring(0, name.length - 9);
			const cleanName = name
				.split("/")
				.filter((p) => !p.startsWith("#"))
				.join("/");

			const nsParts = path.normalize(currentPath).split(path.sep);
			let ns = null;
			for (const part of nsParts) if (part.startsWith("@")) ns = part.substring(1);

			const modData = { path: currentPath, ns: ns, meta: {}, files: {} };

			const jsonPath = path.join(currentPath, "module.json");
			if (fs.existsSync(jsonPath)) {
				try {
					modData.meta = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
				} catch (e) {}
			}

			["shared", "client", "server"].forEach((ctx) => {
				const fPath = path.join(currentPath, `${ctx}.lua`);
				if (fs.existsSync(fPath)) {
					const rawCode = fs.readFileSync(fPath, "utf8");
					const stubs = extractStubs(rawCode, ns, ctx);
					const types = extractEmmyClasses(rawCode);
					let cleanCode = stripLuaComments(rawCode);
					cleanCode = applyBuildConstants(cleanCode, { version: version });
					cleanCode = transformLtassertStatements(cleanCode);
					modData.files[ctx] = { code: cleanCode, stubs: stubs, types: types };
				}
			});

			db.modules[cleanName] = {
				ns: modData.ns,
				meta: modData.meta,
				shared: modData.files.shared
					? { code: modData.files.shared.code, stubs: modData.files.shared.stubs, types: modData.files.shared.types }
					: null,
				client: modData.files.client
					? { code: modData.files.client.code, stubs: modData.files.client.stubs, types: modData.files.client.types }
					: null,
				server: modData.files.server
					? { code: modData.files.server.code, stubs: modData.files.server.stubs, types: modData.files.server.types }
					: null,
			};
			db.registry[cleanName] = relative.replace(/\\/g, "/");
		} else {
			for (const item of items) {
				if (item === "node_modules" || item === ".git" || item === "ltbridge") continue;
				const fullPath = path.join(currentPath, item);
				if (fs.statSync(fullPath).isDirectory()) scan(fullPath);
			}
		}
	}

	console.log("[LTBridge] Compiling modules Ahead-Of-Time...");
	scan(modulesDir);

	for (const [modName, modData] of Object.entries(db.modules)) {
		const processStubs = (stubs) => {
			if (!stubs) return;
			for (const stub of stubs) {
				const formsToExport = [];
				const prefixStr = modData.ns ? `${modData.ns}.` : ``;
				if (stub.metadata.export) {
					formsToExport.push(stub.metadata.export);
					if (stub.metadata.global) {
						const gName = stub.metadata.global === true ? stub.metadata.export : stub.metadata.global;
						formsToExport.push(gName);
					} else {
						formsToExport.push(`${prefixStr}${stub.metadata.export}`);
					}
				} else if (stub.metadata.global) {
					const gName = stub.metadata.global === true ? stub.funcName : stub.metadata.global;
					formsToExport.push(gName);
				} else {
					formsToExport.push(modData.ns ? `${modData.ns}.${stub.funcName}` : stub.funcName);
				}
				formsToExport.push(stub.funcName);
				if (stub.metadata.alias) stub.metadata.alias.forEach((al) => formsToExport.push(`${prefixStr}${al}`));

				for (const form of formsToExport) {
					if (!db.exportMap[form]) db.exportMap[form] = [];
					if (!db.exportMap[form].includes(modName)) db.exportMap[form].push(modName);
				}
			}
		};
		if (modData.shared) processStubs(modData.shared.stubs);
		if (modData.client) processStubs(modData.client.stubs);
		if (modData.server) processStubs(modData.server.stubs);
	}

	const outPath = path.join(distDir, "modules.dat");
	fs.writeFileSync(outPath, JSON.stringify(db));
	console.log(`[LTBridge] Compiled ${Object.keys(db.modules).length} modules to ${outPath}`);
}

compile();
