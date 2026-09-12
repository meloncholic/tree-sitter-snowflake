# tree-sitter-snowflake

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for Snowflake SQL.

**Scope: Snowflake only.** This is not a general or multi-dialect SQL grammar and has no
dialect-detection fallback. T-SQL and PostgreSQL syntax are out of scope. A file the grammar
cannot parse produces `ERROR` nodes for a consumer to measure and act on, never a permissive
best-effort tree.

**Status: Tier 1 and Tier 2 coverage complete, plus most of Tier 3.** `SELECT` in full (CTEs incl.
recursive, set operators, joins incl. `LATERAL`, `QUALIFY`, `GROUP BY GROUPING SETS`/`CUBE`/
`ROLLUP`, window functions, `MATCH_RECOGNIZE`, `PIVOT`/`UNPIVOT`), `MERGE`, `CREATE`/`ALTER`/`DROP`
for supported object families (table, view, materialized and dynamic table, stage, file
format, stream, pipe, task, warehouse, database, schema, role, user, sequence, tag, integration,
streamlit, Cortex search service and agent, semantic view), `GRANT`/`REVOKE` incl. future grants,
`COPY INTO` both directions, `PUT`/`GET`/`LIST`/`REMOVE`, `CALL`/`USE`/`SET`/`UNSET`/`SHOW`/
`DESCRIBE`/`COMMENT ON`, transactions, procedure and function definitions with Snowflake Scripting
control flow complete through cursors, `RESULTSET`, `EXECUTE IMMEDIATE`, and `EXCEPTION ... WHEN`,
and the semi-structured `:` path operator, `LATERAL FLATTEN`, `IDENTIFIER(...)`, `* EXCLUDE`/
`RENAME`, session variables (`$var`), positional/named binds, `ARRAY`/`OBJECT` constructors, and
`=>` named arguments. See "Consumer integration" below for application guidance.

The repository includes synthetic fixtures and a parse-rate harness for evaluating a local
Snowflake SQL corpus. See "Testing" below for validation commands.

This is a from-scratch grammar, not a fork — see `NOTICE` for what it adapts from third-party
sources (a substantially reduced dollar-quoting scanner) and what it takes as style reference
(repository layout and rule organization).

## Foreign-language procedure and function bodies

A `LANGUAGE JAVASCRIPT`/`PYTHON`/`JAVA`/`SCALA` body is not Snowflake SQL — it is a different
language carried inside the body's delimiters. This grammar does not parse that language, but it
exposes the body so another grammar can:

- The declared language is a `language` field on the `create_procedure`/`create_function`/
  `alter_procedure`/`alter_function` node.
- The body's content — the text between the delimiters, excluding the delimiters themselves — is
  its own node, distinct for the two delimiter forms Snowflake accepts:
  `dollar_quoted_body`/`dollar_quoted_script`/`dollar_quoted_expression` for `$$ ... $$`, and
  `string_body` for the single-quoted `AS '...'` form.
- `string_body`'s doubled-apostrophe escape (`''`) and backslash escapes are their own
  `doubled_quote`/`escape` nodes inside the content, so a consumer can reconstruct the real text
  and map a position in it back to a position in the file without re-lexing the body by hand.
- `queries/injections.scm` ships with the grammar, one branch per language. It only reaches the
  dollar-quoted form — tree-sitter's injection mechanism parses a byte range of the original
  source, and the single-quoted form's `''` doubling means its byte range is not the embedded
  language's source.

The companion [`snowflake-bodies`](snowflake-bodies/README.md) crate implements extraction,
source-position mapping, embedded parsing, and advisory restriction checks. JavaScript and Python
are included; Java and Scala are optional Cargo features. The grammar package does not depend on
the companion. See `docs/consumer-integration.md` for measurement and masking integration.

## Node package metadata

The default export exposes `name`, `language`, and `nodeTypeInfo` on Linux and Windows.
`nodeTypeInfo` contains the entries from `src/node-types.json`: an entry's optional `children`
property is an object with `multiple`, `required`, and `types` properties, not an array.
Leaf entries can omit both `fields` and `children`.

```js
import Snowflake from 'tree-sitter-snowflake';

const program = Snowflake.nodeTypeInfo.find((node) => node.type === 'program');
console.log(program?.children?.types);
```

Release jobs require a version tag on `main` matching the Cargo package version and publish
from the commit that passed verification. The npm and GitHub Packages archives carry that
same version in both `package.json` and `tree-sitter.json`.

## Building

```sh
npm ci --ignore-scripts
npm rebuild tree-sitter-cli
npx --no-install tree-sitter generate
cargo build
```

The generated parser (`src/parser.c`, `src/grammar.json`, `src/node-types.json`) is committed, so
consumers build the C parser through `cc` during `cargo build` without needing the tree-sitter CLI
themselves. CI regenerates from `grammar.js` on every change and fails if the committed output
differs.

`src/scanner.c` lexes `$$`-delimited bodies — the content between the delimiters can contain
anything, including the grammar's own operators and unbalanced quotes, which a regex cannot match.
It must be compiled alongside `src/parser.c`; vendoring one without the other produces a link
error or a parser that cannot lex a dollar-quoted body.

`generate` takes under a minute on this grammar. Run it with a time cap and read the exit code,
and check that `src/parser.c`'s modification time moved before trusting a test run — a failed
`generate` leaves the previous parser in place and writes nothing.

## Testing

```sh
tree-sitter test
cargo test --workspace
cargo test -p snowflake-bodies --all-features
```

On a machine without MSVC, point the CLI at another C compiler:

```sh
CC=gcc CXX=g++ tree-sitter test
```

`test/corpus/` holds the per-construct tree assertions (the regression suite); `test/fixtures/`
holds whole synthetic Snowflake files, checked by `tools/fixture-check.mjs` for zero `ERROR`/
`MISSING` and zero zero-width nodes, and by `tools/fixture-leak-grep.mjs` for absence of any
source-corpus identifier. `tools/keyword-probe.mjs` probes every keyword against the AS-less
alias slot and the unqualified column slot, the two positions where a keyword can silently eat an
identifier. `tools/node-kinds.mjs --check` diffs the exported node-kind set against the committed
snapshot in `test/node-kinds.txt` — a rename or removal there is a major version bump.
`tools/parse-rate/parse-rate.mjs` measures the parse-rate budget over a real, locally-provided
Snowflake corpus supplied by the caller. The committed fixtures are synthetic.

## Consumer integration

Editors, source-analysis tools, and linters can use the grammar's named nodes and query files
to analyze Snowflake SQL. The companion `snowflake-bodies` crate provides embedded-language
parsing and source mapping. Tools with their own SQL parser can also use this grammar for
differential testing.

See [Consumer integration](docs/consumer-integration.md) for structural node mappings, explicit
dialect selection, comment/string masking, body analysis, and version compatibility.

## License

MIT — see `LICENSE` and `NOTICE`.
