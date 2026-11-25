import assert from 'node:assert/strict';
import { test } from 'node:test';
import { stripLuaComments, stripLuaForScan } from '../src/lua/source';
import { transformLtassertStatements } from '../src/lua/transform';
import { applyBuildConstants } from '../src/lua/constants';

test('treats mismatched long-string delimiters as literal text', () => {
  const source = 'local doc = [=[ A ]] LT.Notify.Send("text") -- keep ]=]\nreturn doc';
  assert.equal(stripLuaComments(source), source);
  assert.ok(!(stripLuaForScan(source)).includes('LT.Notify'));
});

test('replaces build constants without changing Lua literals', () => {
  const literal = `local text = [=[__LT_VERSION = 'old' and __LT_DISABLE_DEBUG = true]=]`;
  const code = `${literal}\nlocal __LT_VERSION = 'old'\nlocal __LT_DISABLE_DEBUG = true`;
  assert.equal(applyBuildConstants(code, { version: '1.4.3', disableDebug: false }), `${literal}\nlocal __LT_VERSION = '1.4.3'\nlocal __LT_DISABLE_DEBUG = false`);
});

test('only wraps standalone ltassert calls', () => {
  assert.equal(transformLtassertStatements('return ltassert(true)'), 'return ltassert(true)');
  const nested = 'local result = fn(\n  ltassert(true)\n)';
  assert.equal(transformLtassertStatements(nested), nested);
  const multiline = 'return\n  ltassert(true)';
  assert.equal(transformLtassertStatements(multiline), multiline);
  const chained = 'ltassert(ok)\n-- another argument list\n()';
  assert.equal(transformLtassertStatements(chained), chained);
  assert.equal(transformLtassertStatements('  ltassert(true)'), '  if not ltassert(true) then return false end');
  assert.equal(transformLtassertStatements('local message = "ready"\nltassert(ok)'), 'local message = "ready"\nif not ltassert(ok) then return false end');
  const callback = 'run(function()\n  ltassert(true)\nend)';
  assert.equal(transformLtassertStatements(callback), 'run(function()\n  if not ltassert(true) then return false end\nend)');
});

test('masks CfxLua hashes and transforms spaced standalone assertions', () => {
  const source = 'return `LT.Notify`';
  assert.equal(stripLuaComments(source), source);
  assert.doesNotMatch(stripLuaForScan(source), /LT\.Notify/);
  assert.equal(transformLtassertStatements('ltassert (false)'), 'if not ltassert(false) then return false end');
});
