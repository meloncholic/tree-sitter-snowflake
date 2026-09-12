import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';

export function docsOnly(files) {
  // Only prose outside source/test trees can skip compilation.
  return files.length > 0 && files.every((path) => /^(?:[^/]+\.md|docs\/.*\.md)$/.test(path));
}

export function changedPaths(base, head, run = execFileSync) {
  return run('git', ['diff', '--no-renames', '--name-only', '-z', `${base}...${head}`], { encoding: 'utf8' }).split('\0').filter(Boolean);
}

export function verifyResults(needs, event, draft) {
  assert(!draft, 'Draft pull requests require a full verification run');
  for (const [job, value] of Object.entries(needs)) {
    let expected = 'success';
    if (job === 'pr-title' && event !== 'pull_request') expected = 'skipped';
    if (['verify', 'consumer-pin', 'node-binding'].includes(job) && needs.changes?.outputs?.build === 'false') expected = 'skipped';
    assert.equal(value.result, expected, `${job} must finish as ${expected}`);
  }
}

if (process.argv[2] === 'changes') {
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
  let build = true;
  if (process.env.GITHUB_EVENT_NAME === 'pull_request') {
    const { base, head } = event.pull_request;
    const files = changedPaths(base.sha, head.sha);
    build = !docsOnly(files);
  }
  appendFileSync(process.env.GITHUB_OUTPUT, `build=${build}\n`);
} else if (process.argv[2] === 'verify') {
  verifyResults(JSON.parse(process.env.JOB_RESULTS), process.env.GITHUB_EVENT_NAME, process.env.IS_DRAFT === 'true');
}
