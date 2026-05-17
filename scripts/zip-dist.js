const { execSync } = require("child_process");
const fs = require("fs-extra");
const path = require("path");

const rootDir = path.join(__dirname, "..");
const distDir = path.join(rootDir, "dist");
const releaseDir = path.join(rootDir, "release");
const { version } = require("../package.json");

const requiredFiles = ["ltbridge.js", "modules.dat"];

function zipDist() {
	for (const file of requiredFiles) {
		const filePath = path.join(distDir, file);
		if (!fs.existsSync(filePath)) {
			console.error(`[LTBridge] Missing dist/${file}. Run "npm run build" first.`);
			process.exit(1);
		}
	}

	fs.ensureDirSync(releaseDir);

	const zipName = `ltbridge-v${version}.zip`;
	const zipPath = path.join(releaseDir, zipName);

	if (fs.existsSync(zipPath)) {
		fs.removeSync(zipPath);
	}

	try {
		execSync(`tar -a -cf "${zipPath}" -C "${distDir}" .`, { stdio: "inherit" });
	} catch (err) {
		console.error("[LTBridge] Failed to create zip. Ensure 'tar' is available on your system.");
		process.exit(1);
	}

	console.log(`[LTBridge] Packaged release/${zipName} (${requiredFiles.length} files)`);
}

zipDist();
