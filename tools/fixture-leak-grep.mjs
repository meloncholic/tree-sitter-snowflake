#!/usr/bin/env node
// Leak grep: asserts the committed fixtures contain none of the real
// identifiers, names, and paths observed in the source repositories the
// fixture shapes were mined from. Run whenever a fixture is added or
// edited. A hit means the scrub failed; fix the fixture, not this list.
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const repo = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

// Real names observed in the source corpora: databases, schemas,
// warehouses, roles, integrations, storage accounts, business and
// vendor words. Generic Snowflake/system vocabulary (SYSADMIN,
// INFORMATION_SCHEMA, CURRENT_TIMESTAMP, ...) is deliberately absent.
const needles = [
  'live', 'dev', 'test', 'cortex_dev',
  'syteline', 'syteline_dev', 'salesforce', 'stackline', 'google_analytics',
  'mip', 'mdm', 'crm', 'locally', 'data_warehouse', 'reporting',
  'compute_wh', 'agent_wh',
  'service_role', 'claude_role', 'bi_service_role', 'mcp_access_role',
  'azure_storage_integration',
  'martinsnowflakestaging',
  'martin', 'nazareth', 'navojoa', 'wells_fargo', 'guitar_center',
  'rowpointer', 'siteref', 'vend_num', 'aptrxp', 'artran',
  'kimball',
  'merge_dim', 'sp_refresh', 'task_refresh', 'fn_add_workdays',
  'exception_log', 'normali',
];

const fixtures = readdirSync(join(repo, 'test/fixtures')).filter((f) => f.endsWith('.sql'));
let hits = 0;
for (const f of fixtures) {
  const text = readFileSync(join(repo, 'test/fixtures', f), 'utf8').toLowerCase();
  for (const n of needles) {
    // Word boundaries: `test` must not match inside `createStatement`,
    // and `dev` must not match inside `device`.
    const re = new RegExp(`(^|[^a-z0-9_])${n.replace(/_/g, '[ _]')}([^a-z0-9_]|$)`);
    if (re.test(text)) {
      console.log(`LEAK ${f}: ${n}`);
      hits++;
    }
  }
}
console.log(hits ? `${hits} leak(s) found` : `clean: ${fixtures.length} fixtures, no source-corpus identifiers`);
process.exit(hits ? 1 : 0);
