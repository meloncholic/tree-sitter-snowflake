# Contributing

## Build

```sh
npm install --no-save tree-sitter-cli@0.27.0
npx --yes --package=tree-sitter-cli@0.27.0 -- tree-sitter generate
cargo build
```

The generated parser (`src/parser.c`, `src/grammar.json`, and
`src/node-types.json`) is committed. Regenerate and commit the diff after any
`grammar.js` change. A failed generation leaves the prior parser in place, so
confirm that generation succeeded before trusting a subsequent test run.

## Test

```sh
CC=gcc CXX=g++ npx --yes --package=tree-sitter-cli@0.27.0 -- tree-sitter test
node tools/node-kinds.mjs --check
node tools/fixture-check.mjs
node tools/fixture-leak-grep.mjs
node tools/keyword-probe.mjs
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test
```

`test/corpus/` holds per-construct tree assertions. `test/fixtures/*.sql` are
larger real-shaped inputs checked for `ERROR`, `MISSING`, and zero-width nodes.
The fixture identifier check prevents private source-corpus names from entering
the public repository.

## Pull requests

- Regenerate and commit the parser and node-kind snapshot with any grammar
  change; CI rejects drift in either artifact.
- Add a corpus case or extend a fixture for every newly supported construct.
- Keep node-kind renames for a breaking release: consumers match these names
  at runtime.
- Keep the full Rust verification suite warning-free.
