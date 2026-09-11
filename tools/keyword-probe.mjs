#!/usr/bin/env node
// Keyword-slot probe. For every keyword spelled in grammar/keywords.js,
// parses both positions where an ordinary identifier sits:
//   alias slot:   SELECT * FROM db.schema.t <word>
//   column slot:  SELECT <word> FROM t
// A keyword valid in one of those parser states is substituted by keyword
// extraction and breaks the probe. Failures are expected — and correct —
// for two documented classes:
//
//   1. Snowflake's reserved words (they cannot be identifiers in Snowflake
//      either).
//   2. Clause and function keywords that REQUIRE more tokens after them
//      (LIMIT n, PIVOT (...), EXCEPT <query>, MATCH_RECOGNIZE (...),
//      WINDOW w AS (...), TOP n, EXTRACT(...), IDENTIFIER(...),
//      INTERVAL 'n' DAY). Snowflake itself rejects these words bare in
//      the slot, so the grammar erroring is faithful behavior; the corpus
//      has been grepped and none is used as a bare column or alias.
//
// Anything else failing is a regression: a new keyword is eating an
// identifier position. Run this whenever a keyword is added.
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = fileURLToPath(new URL('..', import.meta.url));
const exeCandidates = [
  join(repo, 'node_modules/tree-sitter-cli/tree-sitter.exe'),
  join(repo, 'node_modules/tree-sitter-cli/tree-sitter'),
];
const cli = exeCandidates.find((p) => statSync(p, { throwIfNoEntry: false })?.isFile()) ?? 'tree-sitter';

const kwFile = readFileSync(join(repo, 'grammar/keywords.js'), 'utf8');
const words = [...new Set([...kwFile.matchAll(/make_keyword\("([a-z_0-9]+)"/g)].map((m) => m[1]))].sort();

// Snowflake's documented reserved words.
const reserved = new Set(('all alter and any as between by case cast check column connect connection constraint create cross current current_date current_time current_timestamp current_user delete distinct drop else exists false following for from full grant group gscluster having ilike in increment inner insert intersect into is join lateral left like localtime localtimestamp minus natural not null of on or order organization qualify regexp revoke right rlike row rows sample select set some start table tablesample then to trigger true try_cast union unique update using values view when whenever where with').toUpperCase().split(' '));

// Clause/function keywords that need more tokens after them (class 2).
const clauseKeywords = new Set(['except', 'limit', 'match_recognize', 'pivot', 'unpivot', 'window', 'extract', 'identifier', 'interval', 'top']);

const scratch = join(repo, 'tmp', 'kwprobe-' + process.pid);
mkdirSync(scratch, { recursive: true });
const cases = [];
for (const w of words) {
  cases.push({ word: w, slot: 'alias', sql: `SELECT * FROM db.schema.t ${w}\n`, wantIdentifiers: 4 });
  cases.push({ word: w, slot: 'column', sql: `SELECT ${w} FROM t\n`, wantIdentifiers: 2 });
}
cases.forEach((c, i) => { c.file = join(scratch, `${i}.sql`); writeFileSync(c.file, c.sql); });

const failures = [];
for (const c of cases) {
  const single = spawnSync(cli, ['parse', c.file], {
    cwd: repo, encoding: 'utf8', maxBuffer: 1 << 26,
    env: { ...process.env, CC: 'gcc', CXX: 'g++' },
  });
  const t = single.stdout.replace(/\[[0-9;]*m/g, '');
  const err = /ERROR|MISSING/.test(t);
  const ids = (t.match(/\(identifier[ \n)]/g) || []).length;
  if (err || ids !== c.wantIdentifiers) {
    failures.push({
      ...c, err, ids,
      expected: reserved.has(c.word.toUpperCase()) || clauseKeywords.has(c.word),
    });
  }
}

const regressions = failures.filter((f) => !f.expected);
console.log(`probed ${cases.length} cases (${words.length} keywords x 2 slots)`);
console.log(`failures: ${failures.length}, all in the documented reserved/clause-keyword classes: ${regressions.length === 0}`);
for (const r of regressions) {
  console.log(`  REGRESSION [${r.slot}] ${r.word}  err=${r.err} identifiers=${r.ids}/${r.wantIdentifiers}`);
}
process.exit(regressions.length ? 1 : 0);
