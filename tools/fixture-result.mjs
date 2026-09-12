import assert from 'node:assert/strict';

export function fixtureResult(proc) {
  assert(!proc.error, `Could not run parser: ${proc.error?.message}`);
  assert.equal(proc.signal, null, `Parser terminated by ${proc.signal}`);
  assert.equal(proc.status, 0, `Parser exited ${proc.status}: ${proc.stderr}`);
  const tree = proc.stdout.replace(/\u001b\[[0-9;]*m/g, '');
  assert(/^\(program\s/m.test(tree), 'Parser did not return a program tree');
  return {
    errors: (tree.match(/ERROR|MISSING/g) || []).length,
    zeroWidth: (tree.match(/\[([0-9]+), ([0-9]+)\] - \[\1, \2\]/g) || []).length,
  };
}
