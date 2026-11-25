import assert from 'node:assert/strict';
import { test } from 'node:test';
import { releaseSource, releaseVersion } from '../scripts/release-version';

test('release compares stable versions and keeps a pending draft on its source commit', () => {
  assert.equal(releaseVersion('1.4.2', '2.0.0'), '2.0.0');
  assert.equal(releaseVersion('2.0.0', '2.0.0'), undefined);
  assert.throws(() => releaseVersion('2.0.0', '1.4.2'), /must increase/);
  assert.equal(releaseSource('new', undefined, undefined, false), 'new');
  assert.equal(releaseSource('new', 'old', 'old', true), 'old');
  assert.throws(() => releaseSource('new', undefined, 'old', false), /another commit/);
  assert.throws(() => releaseSource('new', undefined, undefined, true), /matching release draft/);
});
