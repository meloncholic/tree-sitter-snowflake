# tree-sitter-snowflake

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for Snowflake SQL.

**Scope: Snowflake only.** This is not a general or multi-dialect SQL grammar and has no
dialect-detection fallback. T-SQL and PostgreSQL syntax are out of scope. A file the grammar
cannot parse produces `ERROR` nodes for a consumer to measure and act on, never a permissive
best-effort tree.

**Status: Tier 1 and Tier 2 coverage complete, plus most of Tier 3.** `SELECT` in full (CTEs incl.
recursive, set operators, joins incl. `LATERAL`, `QUALIFY`, `GROUP BY GROUPING SETS`/`CUBE`/
`ROLLUP`, window functions, `MATCH_RECOGNIZE`, `PIVOT`/`UNPIVOT`), `MERGE`, `CREATE`/`ALTER`/`DROP`
for every object family the org scripts (table, view, materialized and dynamic table, stage, file
format, stream, pipe, task, warehouse, database, schema, role, user, sequence, tag, integration,
streamlit, Cortex search service and agent, semantic view), `GRANT`/`REVOKE` incl. future grants,
`COPY INTO` both directions, `PUT`/`GET`/`LIST`/`REMOVE`, `CALL`/`USE`/`SET`/`UNSET`/`SHOW`/
`DESCRIBE`/`COMMENT ON`, transactions, procedure and function definitions with Snowflake Scripting
control flow complete through cursors, `RESULTSET`, `EXECUTE IMMEDIATE`, and `EXCEPTION ... WHEN`,
and the semi-structured `:` path operator, `LATERAL FLATTEN`, `IDENTIFIER(...)`, `* EXCLUDE`/
`RENAME`, session variables (`$var`), positional/named binds, `ARRAY`/`OBJECT` constructors, and
`=>` named arguments. Not yet consumed by any downstream project — see "Consumers" below.

Measured against the two Snowflake repositories this grammar was built to unblock (see
`tools/parse-rate/BASELINE.md`): 99.8% of files in `snowflake` and 100% of files in
`snowflake-dw` parse with zero `ERROR`/`MISSING` bytes, against a 0.1%/17.4% baseline for the
general-SQL grammar the org used before this one existed.

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
  `string_body` for the single-quoted `AS '...'` form, which is the one every JavaScript procedure
  in the org's corpus actually uses.
- `string_body`'s doubled-apostrophe escape (`''`) and backslash escapes are their own
  `doubled_quote`/`escape` nodes inside the content, so a consumer can reconstruct the real text
  and map a position in it back to a position in the file without re-lexing the body by hand.
- `queries/injections.scm` ships with the grammar, one branch per language. It only reaches the
  dollar-quoted form — tree-sitter's injection mechanism parses a byte range of the original
  source, and the single-quoted form's `''` doubling means its byte range is not the embedded
  language's source.

See `docs/consumer-integration.md` for what a consumer does with this: the second-parse step for
both body forms, position mapping for the single-quoted case, and the "unmeasured, not zero"
reporting rule for a language the host has no grammar for.

## Building

```sh
npx --package=tree-sitter-cli@0.27.0 -- tree-sitter generate
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
Snowflake corpus (see `tools/parse-rate/BASELINE.md` — the corpus itself is private and not
committed).

## Consumers

`cadence` (source measurement) and `marlin` (structural and vocabulary linting) both already link
`tree-sitter-javascript` and `tree-sitter-python`, so consuming this grammar's foreign-language
body injection costs neither a new dependency for the two languages the org's corpus actually
uses. `docs/consumer-integration.md` covers the profile/masking-mode shape each needs and the
second-parse step for foreign-language bodies. `clause` (SQL linting and formatting) is
undecided — see that document for the open question.

## License

MIT — see `LICENSE` and `NOTICE`.
