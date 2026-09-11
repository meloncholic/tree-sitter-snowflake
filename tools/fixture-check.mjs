#!/usr/bin/env node
// Fixture check: parses every test/fixtures/*.sql and reports, per file,
// ERROR/MISSING node counts and zero-width nodes (equal start and end
// positions), which the error grep cannot see. Exits non-zero if any file
// has either. Zero ERROR/MISSING is not proof a fixture is valid Snowflake
// (a parser has no semantic layer), but it is the regression signal.
import { spawnSync } from 'node:child_process';
import { readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = fileURLToPath(new URL('..', import.meta.url));
const exeCandidates = [
  join(repo, 'node_modules/tree-sitter-cli/tree-sitter.exe'),
  join(repo, 'node_modules/tree-sitter-cli/tree-sitter'),
];
const exe = exeCandidates.find((p) => statSync(p, { throwIfNoEntry: false })?.isFile());
const cli = exe ?? 'tree-sitter';
const fixtures = readdirSync(join(repo, 'test/fixtures')).filter((f) => f.endsWith('.sql'));

let bad = 0;
for (const f of fixtures) {
  const proc = spawnSync(cli, ['parse', join('test/fixtures', f)], {
    cwd: repo, encoding: 'utf8', maxBuffer: 1 << 26,
    env: { ...process.env, CC: 'gcc', CXX: 'g++' },
  });
  const t = proc.stdout;
  const errors = (t.match(/ERROR|MISSING/g) || []).length;
  const zw = (t.match(/\[([0-9]+), ([0-9]+)\] - \[\1, \2\]/g) || []).length;
  if (errors || zw) {
    bad++;
    console.log(`${f}: errors=${errors} zero-width=${zw}`);
  }
}
console.log(bad ? `${bad}/${fixtures.length} fixture files with problems` : `all ${fixtures.length} fixtures parse clean (no ERROR/MISSING, no zero-width nodes)`);
process.exit(bad ? 1 : 0);
