const fs = require("fs");
const path = require("path");

let _dbCache = null;

function getDatabase() {
	if (_dbCache) return _dbCache;
	const dbPath = path.join(__dirname, "..", "dist", "modules.dat");
	if (!fs.existsSync(dbPath)) {
		console.log(`\x1b[31m✖ LTBridge is not compiled. Please run 'npm run build' first.\x1b[0m`);
		process.exit(1);
	}
	_dbCache = JSON.parse(fs.readFileSync(dbPath, "utf8"));
	return _dbCache;
}

function getModuleRegistry() {
	return getDatabase().registry;
}

function getModuleData(modName) {
	return getDatabase().modules[modName];
}

module.exports = { getModuleRegistry, getDatabase, getModuleData };
