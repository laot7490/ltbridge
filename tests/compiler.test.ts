import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { buildSync } from 'esbuild';

test('compiles a fresh catalog without writing module metadata', () => {
  const root = process.cwd();
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'ltbridge-compiler-'));
  fs.cpSync(path.join(root, 'modules'), path.join(fixture, 'modules'), { recursive: true });
  fs.copyFileSync(path.join(root, 'package.json'), path.join(fixture, 'package.json'));
  fs.copyFileSync(path.join(root, "THIRD_PARTY_NOTICES.txt"), path.join(fixture, "THIRD_PARTY_NOTICES.txt"));
  const compiler = path.join(fixture, 'dist', 'compiler.cjs');
  buildSync({ entryPoints: [path.join(root, 'scripts', 'compile.ts')], outfile: compiler, bundle: true, platform: 'node' });
  const modulePath = path.join(fixture, 'modules', '__init__', 'module.json');
  fs.writeFileSync(modulePath, '{"dependencies":["fixture"]}\n');
  const build = spawnSync(process.execPath, [compiler], {
    cwd: fixture,
    env: { ...process.env, NODE_PATH: path.join(root, 'node_modules') },
    encoding: 'utf8',
  });
  assert.equal(build.status, 0, build.stdout + build.stderr);
  const database = JSON.parse(fs.readFileSync(path.join(fixture, 'dist', 'modules.dat'), 'utf8'));
  assert.ok(database.modules['@Notify']);
  assert.ok(!Object.hasOwn(database.publicExports, 'Target.FixOptions'));
  for (const [id, relative] of Object.entries(database.registry)) {
    if (id === '__init__') continue;
    const metadata = JSON.parse(fs.readFileSync(path.join(fixture, 'modules', String(relative), 'module.json'), 'utf8'));
    assert.deepEqual(database.modules[id].dependencies, id === '@Logger' ? [] : metadata.dependencies, id);
  }
  assert.ok(!database.modules.__init__.dependencies.includes('fixture'));
  assert.equal(fs.readFileSync(modulePath, 'utf8'), '{"dependencies":["fixture"]}\n');
});
