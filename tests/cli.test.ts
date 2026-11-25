import { createHash } from 'node:crypto';
import { execFileSync, spawn } from 'node:child_process';
import { once } from 'node:events';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { stripVTControlCharacters } from 'node:util';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { version } from '../package.json';

async function waitFor(condition: () => boolean) {
  const deadline = Date.now() + 5000;
  while (!condition()) {
    assert.ok(Date.now() < deadline, 'Timed out waiting for watcher');
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
}

const cli = path.resolve('dist/ltbridge.js');

function resource() {
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'ltbridge-resource-'));
  fs.mkdirSync(path.join(cwd, 'ltbridge'));
  const config = path.join(cwd, 'ltbridge/config.json');
  fs.writeFileSync(config, JSON.stringify({ version, modules: [], bundle: false, extra: 'keep' }));
  const manifest = path.join(cwd, 'fxmanifest.lua');
  fs.writeFileSync(manifest, "fx_version 'cerulean'\ngame 'gta5'\nclient_script 'main.lua'\n");
  const run = (...args: string[]) => execFileSync(process.execPath, [cli, ...args], { cwd, encoding: 'utf8' });
  return { cwd, config, manifest, run };
}

function unpack(cwd: string) {
  const isolated = path.join(cwd, 'standalone');
  fs.mkdirSync(isolated);
  execFileSync(process.execPath, [process.env.npm_execpath!, 'pack', '--ignore-scripts', '--pack-destination', isolated]);
  const archive = fs.readdirSync(isolated).find((name) => name.endsWith('.tgz'));
  assert.ok(archive);
  execFileSync('tar', ['-xzf', path.join(isolated, archive), '-C', isolated]);
  return path.join(isolated, 'package/dist/ltbridge.js');
}

test('standalone CLI maintains a resource from add to prune', () => {
  const { cwd, config, manifest, run } = resource();
  const executable = unpack(cwd);
  const standalone = (...args: string[]) => execFileSync(process.execPath, [executable, ...args], { cwd, encoding: 'utf8' });
  assert.equal(standalone('--version').trim(), version);
  standalone('build');
  const output = path.join(cwd, 'ltbridge/modules');
  const custom = path.join(output, 'notes.lua');
  fs.writeFileSync(custom, 'return 42');
  run('add', 'Notify');
  assert.ok((run('why', 'Notify')).includes('explicitly added'));
  assert.match(stripVTControlCharacters(run('list')), /^\s*✔ @Notify[ \t]*$/m);
  assert.ok((fs.readFileSync(manifest, 'utf8')).includes('main.lua'));
  const generated = path.join(output, 'client.lua');
  const before = fs.statSync(generated).mtimeMs;
  run('sync');
  assert.equal(fs.statSync(generated).mtimeMs, before);
  fs.writeFileSync(generated, fs.readFileSync(generated, 'utf8').replaceAll('\n', '\r\n'));
  run('sync');
  assert.ok(!(fs.readFileSync(generated, 'utf8')).includes('\r'));
  run('api');
  assert.equal(fs.existsSync(path.join(cwd, 'ltbridge/api.lua')), true);
  run('prune');
  assert.equal(fs.existsSync(generated), false);
  assert.equal(fs.readFileSync(custom, 'utf8'), 'return 42');
  const saved = JSON.parse(fs.readFileSync(config, 'utf8'));
  assert.deepEqual(saved.modules, []);
  assert.equal(saved.extra, 'keep');
});

test('list and why report a corrupt config instead of an empty project', () => {
  const { config, run } = resource();
  fs.writeFileSync(config, '{"bundle":"true"}');
  assert.throws(() => run('list'), /Expected boolean config field bundle/);
  assert.throws(() => run('why', 'Notify'), /Expected boolean config field bundle/);
});

test('watch adds modules, retains them on unlink and responds to config edits', async () => {
  const { cwd, config } = resource();
  const child = spawn(process.execPath, [unpack(cwd), 'build', '--watch'], { cwd });
  let output = '';
  child.stdout.on('data', (data) => { output += String(data); });
  child.stderr.on('data', (data) => { output += String(data); });
  const lua = path.join(cwd, 'main.lua');
  try {
    await waitFor(() => (output).includes('Watching Lua files'));
    fs.writeFileSync(lua, 'LT.Notify.Send("hello")');
    await waitFor(() => (fs.readFileSync(config, 'utf8')).includes('@Notify'));
    fs.writeFileSync(config, JSON.stringify({ version, modules: [], bundle: false }));
    await waitFor(() => (fs.readFileSync(config, 'utf8')).includes('@Notify'));
    const api = path.join(cwd, 'ltbridge/api.lua');
    fs.unlinkSync(api);
    fs.writeFileSync(config, '{"bundle":"invalid"}');
    await waitFor(() => output.includes('Expected boolean config field bundle'));
    fs.writeFileSync(config, JSON.stringify({ version, modules: ['@Notify'], bundle: false }));
    await waitFor(() => fs.existsSync(api));
    fs.unlinkSync(lua);
    fs.writeFileSync(config, JSON.stringify({ version, modules: ['@Notify'], bundle: true }));
    const generated = path.join(cwd, 'ltbridge/modules/client.lua');
    await waitFor(() => (fs.readFileSync(generated, 'utf8')).includes('@license LT Bridge'));
    assert.deepEqual(JSON.parse(fs.readFileSync(config, 'utf8')).modules, ['@Notify']);
  } finally {
    if (child.exitCode === null) {
      const exit = once(child, 'exit');
      child.kill();
      await exit;
    }
  }
});


test('invalid build preserves previous output and spaced references survive prune', () => {
  const { cwd, config, manifest, run } = resource();
  run('add', 'Notify');
  const output = path.join(cwd, 'ltbridge/modules/client.lua');
  const before = [output, manifest].map((file) => fs.readFileSync(file, 'utf8'));
  const invalid = JSON.stringify({ version, modules: ['@Missing'] });
  fs.writeFileSync(config, invalid);
  assert.throws(() => run('build'), /Unknown LTBridge module/);
  assert.deepEqual([output, manifest].map((file) => fs.readFileSync(file, 'utf8')), before);
  assert.equal(fs.readFileSync(config, 'utf8'), invalid);

  fs.writeFileSync(config, JSON.stringify({ version, modules: ['@Math/Clamp'] }));
  fs.writeFileSync(path.join(cwd, 'main.lua'), 'local x = LT.Math . Clamp(4, 0, 9)');
  fs.unlinkSync(path.join(cwd, 'ltbridge/api.lua'));
  run('prune');
  assert.deepEqual(JSON.parse(fs.readFileSync(config, 'utf8')).modules, ['@Math/Clamp']);
  assert.equal(fs.existsSync(path.join(cwd, 'ltbridge/api.lua')), true);
});


test('a locked resource rejects a second CLI writer and accepts a later build', (t) => {
  const { cwd, config, manifest, run } = resource();
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  const lock = path.join(cwd, 'ltbridge/.write-lock');
  const before = [config, manifest].map((file) => fs.readFileSync(file, 'utf8'));
  fs.writeFileSync(lock, String(process.pid));
  assert.throws(() => run('add', 'Notify'), /Another LTBridge write is in progress/);
  assert.deepEqual([config, manifest].map((file) => fs.readFileSync(file, 'utf8')), before);
  assert.equal(fs.readFileSync(lock, 'utf8'), String(process.pid));
  fs.unlinkSync(lock);
  run('add', 'Notify');
  assert.deepEqual(JSON.parse(fs.readFileSync(config, 'utf8')).modules, ['@Notify']);
  assert.ok(!fs.existsSync(lock));
});


test('renders the full catalog in every output mode with stable Lua hashes', (t) => {
  const { cwd, config, run } = resource();
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  const catalog = JSON.parse(fs.readFileSync(path.join(path.dirname(cli), 'modules.dat'), 'utf8'));
  const output = path.join(cwd, 'ltbridge/modules');
  const hashes = () => fs.readdirSync(output, { withFileTypes: true, recursive: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith('.lua'))
    .map((entry) => path.join(entry.parentPath, entry.name))
    .sort()
    .map((file) => [file, createHash('sha256').update(fs.readFileSync(file)).digest('hex')]);
  for (const bundle of [false, true]) {
    let readableBytes = 0;
    for (const minify of [false, true]) {
      fs.writeFileSync(config, JSON.stringify({ modules: Object.keys(catalog.modules), bundle, minify }));
      assert.doesNotMatch(run('build'), /Minification failed/);
      const first = hashes();
      assert.equal(first.length === 3, bundle);
      const bytes = first.reduce((total, [file]) => total + fs.statSync(file).size, 0);
      if (minify) assert.ok(bytes < readableBytes);
      else readableBytes = bytes;
      assert.doesNotMatch(run('build'), /Minification failed/);
      assert.deepEqual(hashes(), first);
    }
  }
});


test('reports failed minification and preserves the readable Lua chunk', (t) => {
  const { cwd, config } = resource();
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  const executable = path.join(cwd, 'ltbridge.js');
  fs.copyFileSync(cli, executable);
  const catalog = JSON.parse(fs.readFileSync(path.join(path.dirname(cli), 'modules.dat'), 'utf8'));
  const invalidChunk = 'local value = @';
  catalog.modules.__init__.shared.code = invalidChunk;
  fs.writeFileSync(path.join(cwd, 'modules.dat'), JSON.stringify(catalog));
  fs.writeFileSync(config, JSON.stringify({ modules: [], bundle: true, minify: true }));
  const result = execFileSync(process.execPath, [executable, 'build'], { cwd, encoding: 'utf8' });
  assert.match(result, /Minification failed for __init__ shared\.lua/);
  assert.ok(fs.readFileSync(path.join(cwd, 'ltbridge/modules/shared.lua'), 'utf8').includes(invalidChunk));
});
