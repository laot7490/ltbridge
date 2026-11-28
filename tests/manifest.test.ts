import fs from "node:fs";
import { tempDirectory } from "./temp-directory";
import path from "node:path";
import assert from "node:assert/strict";
import { test } from "node:test";
import { prepareManifest } from "../src/build/manifest";

test("only rewrites standalone managed entries in manifest tables", (t) => {
	const root = tempDirectory(t, "ltbridge-manifest-");
	const manifest = path.join(root, "fxmanifest.lua");
	const loader = "'ltbridge/modules/client.lua'";
	const expressions = [
		"choose(" + loader + ")",
		"{ " + loader + " }",
		"alias = " + loader,
		loader + " .. '.backup'",
		"function() return 1, " + loader + ", 2 end",
	].join(",\n  ");
	fs.writeFileSync(manifest, "client_scripts {\n  " + expressions + ",\n  " + loader + " -- old loader\n  , 'main.lua'\n}\n");
	prepareManifest(root, true, false, false)?.();
	const built = fs.readFileSync(manifest, "utf8");
	assert.ok(built.includes(expressions));
	assert.ok(built.includes("-- old loader\n   'main.lua'"));
	assert.ok(built.startsWith("client_scripts {\n    " + loader + ","));
	prepareManifest(root, false, false, false)?.();
	const removed = fs.readFileSync(manifest, "utf8");
	assert.ok(removed.includes(expressions));
	assert.ok(!removed.includes("\n    " + loader + ","));
});

test("leaves comments and custom entries intact when updating managed scripts", (t) => {
	const root = tempDirectory(t, "ltbridge-manifest-");
	const manifest = path.join(root, "fxmanifest.lua");
	const original = [
		"server_scripts { 'ltbridge/modules/server.lua' ; 'extra.lua' }",
		"client_scripts {",
		"  -- 'ltbridge/modules/client.lua', }",
		'  "ltbridge/modules/client.lua",',
		"  'client.lua',",
		"}",
		"",
	].join("\n");
	fs.writeFileSync(manifest, original);
	prepareManifest(root, true, false, false)?.();
	const updated = fs.readFileSync(manifest, "utf8");
	assert.ok(updated.includes("server_scripts {  'extra.lua' }"));
	assert.equal(updated.match(/ltbridge\/modules\/client\.lua/g)?.length, 2);
	assert.ok(updated.includes("-- 'ltbridge/modules/client.lua', }"));
	assert.ok(updated.includes("'client.lua',"));
	prepareManifest(root, true, false, false)?.();
	assert.equal(fs.readFileSync(manifest, "utf8"), updated);
});

test("ignores directive lookalikes in Lua strings and comments", (t) => {
	const root = tempDirectory(t, "ltbridge-manifest-");
	const manifest = path.join(root, "fxmanifest.lua");
	const literal = "local doc = [=[\nshared_script 'example.lua'\n]=]\n-- 'ltbridge/**/*.lua'\n";
	fs.writeFileSync(manifest, literal);
	prepareManifest(root, false, false, true)?.();
	const updated = fs.readFileSync(manifest, "utf8");
	assert.equal(updated.startsWith(literal), true);
	assert.ok(updated.includes("shared_scripts {\n    'ltbridge/modules/shared.lua'"));
	assert.ok(updated.includes("escrow_ignore {\n    'ltbridge/**/*.lua'"));
});

test("puts the loader before a parenthesized user script and removes duplicate managed entries", (t) => {
	const root = tempDirectory(t, "ltbridge-manifest-");
	const manifest = path.join(root, "fxmanifest.lua");
	const managed = "ltbridge/modules/client.lua";
	const user = "client_script('main.lua')";
	fs.writeFileSync(manifest, [user, "client_scripts { '" + managed + "' }", ""].join("\r\n"));
	prepareManifest(root, true, false, false)?.();
	const built = fs.readFileSync(manifest, "utf8");
	assert.equal(built.split(managed).length, 2);
	assert.ok(built.indexOf(managed) < built.indexOf(user));
	assert.doesNotMatch(built, /(?<!\r)\n/);
	prepareManifest(root, true, false, false)?.();
	assert.equal(fs.readFileSync(manifest, "utf8"), built);
	prepareManifest(root, false, false, false)?.();
	assert.ok(!fs.readFileSync(manifest, "utf8").includes(managed));

	fs.writeFileSync(
		manifest,
		[
			"client_scripts { 'main.lua', '" + managed + "', '" + managed + "' }",
			"client_script('" + managed + "')",
			"client_scripts { '" + managed + "', 'other.lua' }",
		].join("\n"),
	);
	prepareManifest(root, true, false, false)?.();
	const ordered = fs.readFileSync(manifest, "utf8");
	assert.equal(ordered.split(managed).length, 2);
	assert.ok(ordered.indexOf(managed) < ordered.indexOf("main.lua"));
	assert.ok(ordered.includes("other.lua"));
	prepareManifest(root, true, false, false)?.();
	assert.equal(fs.readFileSync(manifest, "utf8"), ordered);
});
