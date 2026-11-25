import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import prompts from 'prompts';
import { initProject } from '../src/cli/commands';

test('cancelling any setup question preserves an initialized resource', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ltbridge-init-'));
  try {
    const config = path.join(root, 'ltbridge/config.json');
    const manifest = path.join(root, 'fxmanifest.lua');
    fs.mkdirSync(path.dirname(config));
    const original = '{"modules":["@Notify"],"extra":true}';
    fs.writeFileSync(config, original);
    fs.writeFileSync(manifest, "client_script 'main.lua'\n");
    for (let answered = 0; answered < 4; answered++) {
      prompts.inject([true, ...Array<boolean>(answered).fill(false), new Error('cancel')]);
      await initProject(root);
      assert.equal(fs.readFileSync(config, 'utf8'), original);
      assert.equal(fs.readFileSync(manifest, 'utf8'), "client_script 'main.lua'\n");
      assert.ok(!fs.existsSync(path.join(root, 'ltbridge/modules')));
    }
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
