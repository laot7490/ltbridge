const fs = require("fs-extra");
const path = require("path");

function findBlockEnd(content, openBraceIndex) {
	let depth = 0;
	let i = openBraceIndex;
	const len = content.length;
	let inString = false;
	let stringChar = "";

	while (i < len) {
		const c = content[i];

		if (!inString) {
			if (c === '"' || c === "'") {
				inString = true;
				stringChar = c;
				i++;
				continue;
			}
			if (c === "{") depth++;
			else if (c === "}") {
				depth--;
				if (depth === 0) return i;
			}
		} else {
			if (c === "\\") {
				i += 2;
				continue;
			}
			if (c === stringChar) inString = false;
		}
		i++;
	}

	return -1;
}

function getPluralBlock(content, keywordPlural) {
	const pluralRegex = new RegExp(`^\\s*${keywordPlural}\\s*\\{`, "m");
	const matchPlural = content.match(pluralRegex);
	if (!matchPlural) return null;

	const blockStart = matchPlural.index;
	const openBrace = content.indexOf("{", blockStart);
	if (openBrace === -1) return null;

	const blockEnd = findBlockEnd(content, openBrace);
	if (blockEnd === -1) return null;

	return {
		header: matchPlural[0],
		blockStart,
		blockEnd,
		blockContent: content.substring(blockStart, blockEnd + 1),
	};
}

function injectManifest(targetDir, hasClient, hasServer, hasShared, isIndividual = false) {
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

	const injectBlock = (type, file) => {
		const keywordMatch = type.replace("_scripts", "_script").replace("files", "file");
		const keywordPlural = type;
		const entry = `'ltbridge/modules/${file}'`;

		const block = getPluralBlock(content, keywordPlural);
		if (block) {
			if (block.blockContent.includes(entry)) return;
			const openBrace = content.indexOf("{", block.blockStart);
			content =
				content.substring(0, openBrace + 1) +
				`\n    ${entry},` +
				content.substring(openBrace + 1);
			injected = true;
			return;
		}

		const singularRegex = new RegExp(`^\\s*${keywordMatch}\\s+(['"].+?['"])`, "m");
		const matchSingular = content.match(singularRegex);

		if (matchSingular) {
			if (matchSingular[0].includes(entry)) return;
			const originalFileString = matchSingular[1];
			const replacement = `${keywordPlural} {\n    ${entry},\n    ${originalFileString}\n}`;
			content = content.replace(matchSingular[0], replacement);
			injected = true;
			return;
		}

		content += `\n\n${keywordPlural} {\n    ${entry}\n}`;
		injected = true;
	};

	const removeBlock = (file) => {
		const safeFile = file.replace(/[*.]/g, "\\$&");
		const removeRegex = new RegExp(`\\s*['\"]ltbridge\\/modules\\/${safeFile}['\"],?`, "g");
		if (removeRegex.test(content)) {
			content = content.replace(removeRegex, "");
			injected = true;
		}
	};

	const sharedFile = "shared.lua";
	const clientFile = "client.lua";
	const serverFile = "server.lua";

	if (hasShared) injectBlock("shared_scripts", sharedFile);
	else removeBlock(sharedFile);

	if (hasClient) injectBlock("client_scripts", clientFile);
	else removeBlock(clientFile);

	if (hasServer) injectBlock("server_scripts", serverFile);
	else removeBlock(serverFile);

	const injectEscrow = () => {
		if (content.includes(`'ltbridge/**/*.lua'`) || content.includes(`"ltbridge/**/*.lua"`)) return;

		const block = getPluralBlock(content, "escrow_ignore");
		if (block) {
			const openBrace = content.indexOf("{", block.blockStart);
			content =
				content.substring(0, openBrace + 1) +
				`\n    'ltbridge/**/*.lua',` +
				content.substring(openBrace + 1);
			injected = true;
			return;
		}

		const singularRegex = /^(\s*)escrow_ignore\s+(['"].+?['"])/m;
		const matchSingular = content.match(singularRegex);
		if (matchSingular) {
			const originalFileString = matchSingular[2];
			const replacement = `escrow_ignore {\n    'ltbridge/**/*.lua',\n    ${originalFileString}\n}`;
			content = content.replace(matchSingular[0], replacement);
			injected = true;
			return;
		}

		content += `\n\nescrow_ignore {\n    'ltbridge/**/*.lua'\n}`;
		injected = true;
	};
	injectEscrow();

	if (isIndividual && (hasShared || hasClient)) {
		injectBlock("files", "imports/**/*.lua");
	} else {
		removeBlock("imports/**/*.lua");
	}

	if (injected) {
		fs.writeFileSync(manifestPath, content);
		console.log(`\x1b[32m✓ Updated manifest.\x1b[0m`);
	}
}

module.exports = {
	injectManifest,
	findBlockEnd,
};
