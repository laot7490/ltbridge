import assert from "node:assert/strict";
import { test } from "node:test";
import { extractStubs } from "../src/catalog/stubs";

test("annotation uses the requested table and only its top-level fields", () => {
	const code = [
		"local other_opts = { wrong = true }",
		'local opts = { correct = fn(1, fake); ["other"] = [=[ comma, } ]=] }',
		"--- @ltbridge param opts name",
		"function test(name) end",
	].join("\n");
	assert.ok(extractStubs(code, null, "shared")[0].stubCode.includes("@param name 'correct'|'other'"));
});
