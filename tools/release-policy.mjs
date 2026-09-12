import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync, writeFileSync } from 'node:fs';

export function releaseVersion(tag, manifest) {
  assert(/^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(tag), 'Expected a stable release tag such as v0.1.1');
  const section = manifest.split(/^\[package\]\s*$/m)[1]?.split(/^\[/m)[0];
  const version = section?.match(/^version\s*=\s*"([^"]+)"\s*$/m)?.[1];
  assert.equal(version, tag.slice(1), 'Release tag must match the root Cargo package version');
  return version;
}

export function resolveRelease(tag, run = execFileSync) {
  // Validate before passing the ref to git; branch names and option-like input fail closed.
  releaseVersion(tag, `[package]\nversion = "${tag?.slice(1)}"\n`);
  const git = (args) => run('git', args, { encoding: 'utf8' }).trim();
  const commit = git(['rev-parse', '--verify', `refs/tags/${tag}^{commit}`]);
  git(['merge-base', '--is-ancestor', commit, 'refs/remotes/origin/main']);
  releaseVersion(tag, git(['show', `${commit}:Cargo.toml`]));
  return commit;
}

export function prepareNpm(tag, root = new URL('../', import.meta.url)) {
  const version = releaseVersion(tag, readFileSync(new URL('Cargo.toml', root), 'utf8'));
  for (const name of ['package.json', 'tree-sitter.json']) {
    const path = new URL(name, root);
    const data = JSON.parse(readFileSync(path, 'utf8'));
    if (name === 'package.json') data.version = version;
    else data.metadata.version = version;
    writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
  }
}

if (process.argv[2] === 'resolve') {
  const commit = resolveRelease(process.env.TAG);
  appendFileSync(process.env.GITHUB_OUTPUT, `commit=${commit}\n`);
} else if (process.argv[2] === 'prepare-npm') {
  prepareNpm(process.env.TAG);
}
