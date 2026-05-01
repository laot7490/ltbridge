const fs = require("fs-extra");
const path = require("path");

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

		const pluralRegex = new RegExp(`^\\s*${keywordPlural}\\s*\\{`, "m");
		const matchPlural = content.match(pluralRegex);

		if (matchPlural) {
			const blockStart = matchPlural.index;
			const blockEnd = content.indexOf("}", blockStart);
			const blockContent = blockEnd !== -1 ? content.substring(blockStart, blockEnd) : content.substring(blockStart);
			if (blockContent.includes(`'ltbridge/modules/${file}'`) || blockContent.includes(`"ltbridge/modules/${file}"`)) {
				return;
			}
			const replacement = `${matchPlural[0]}\n    'ltbridge/modules/${file}',`;
			content = content.replace(matchPlural[0], replacement);
			injected = true;
			return;
		}

		const singularRegex = new RegExp(`^\\s*${keywordMatch}\\s+(['"].+?['"])`, "m");
		const matchSingular = content.match(singularRegex);

		if (matchSingular) {
			if (
				matchSingular[0].includes(`'ltbridge/modules/${file}'`) ||
				matchSingular[0].includes(`"ltbridge/modules/${file}"`)
			) {
				return;
			}
			const originalFileString = matchSingular[1];
			const replacement = `${keywordPlural} {\n    'ltbridge/modules/${file}',\n    ${originalFileString}\n}`;
			content = content.replace(matchSingular[0], replacement);
			injected = true;
			return;
		}

		content += `\n\n${keywordPlural} {\n    'ltbridge/modules/${file}'\n}`;
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

		const pluralRegex = new RegExp(`^\\s*escrow_ignore\\s*\\{`, "m");
		const matchPlural = content.match(pluralRegex);
		if (matchPlural) {
			content = content.replace(matchPlural[0], `${matchPlural[0]}\n    'ltbridge/**/*.lua',`);
			injected = true;
			return;
		}

		const singularRegex = new RegExp(`^\\s*escrow_ignore\\s+(['"].+?['"])`, "m");
		const matchSingular = content.match(singularRegex);
		if (matchSingular) {
			const originalFileString = matchSingular[1];
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
		removeBlock("modules/**/*.lua");
	}

	if (injected) {
		fs.writeFileSync(manifestPath, content);
		console.log(`\x1b[32m✓ Updated manifest.\x1b[0m`);
	}
}

module.exports = {
	injectManifest,
};
