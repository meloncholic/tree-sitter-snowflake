import assert from 'node:assert/strict';
import test from 'node:test';
import { changedPaths, docsOnly, verifyResults } from './ci-policy.mjs';

test('renames include the removed source path when classifying prose', () => {
  const files = changedPaths('base', 'head', (command, args) => {
    assert.equal(command, 'git');
    assert.deepEqual(args, ['diff', '--no-renames', '--name-only', '-z', 'base...head']);
    return 'docs/grammar.md\0grammar.js\0';
  });
  assert(!docsOnly(files));
});

test('only explicit prose paths skip builds', () => {
  assert(docsOnly(['README.md', 'docs/consumer-integration.md']));
  for (const files of [[], ['grammar.js'], ['README.md', 'package.json'], ['snowflake-bodies/README.md'], ['test/fixtures/README.md'], ['.github/workflows/verify.yml']]) assert(!docsOnly(files));
});

function results(build = 'true', event = 'pull_request') {
  return Object.fromEntries(['changes', 'verify', 'consumer-pin', 'node-binding', 'secret-scanning', 'pr-title', 'workflow-meta'].map((job) => [job, {
    result: job === 'pr-title' && event !== 'pull_request' || ['verify', 'consumer-pin', 'node-binding'].includes(job) && build === 'false' ? 'skipped' : 'success',
    ...(job === 'changes' ? { outputs: { build } } : {}),
  }]));
}

test('aggregate accepts only deliberate skips', () => {
  for (const event of ['pull_request', 'push', 'workflow_dispatch']) {
    for (const build of ['true', 'false']) {
      const valid = results(build, event);
      verifyResults(valid, event, false);
      assert.throws(() => verifyResults(valid, event, true));
      for (const job of Object.keys(valid)) {
        for (const result of ['failure', 'cancelled', 'skipped']) {
          if (valid[job].result === result) continue;
          assert.throws(() => verifyResults({ ...valid, [job]: { ...valid[job], result } }, event, false));
        }
      }
    }
  }
});
