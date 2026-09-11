# snowflake-bodies

Extract and parse JavaScript, Python, Java, and Scala handlers embedded in Snowflake SQL.
The grammar package remains independent: installing `tree-sitter-snowflake` does not link any
embedded-language grammar. This companion crate is not yet published.

```rust
use snowflake_bodies::{Analyzer, BodyStatus};

let mut analyzer = Analyzer::new()?;
let sql = "CREATE PROCEDURE p() RETURNS STRING LANGUAGE JAVASCRIPT AS 'eval(''1'');';";
let analysis = analyzer.analyze(sql)?;
assert!(analysis.sql_errors.is_empty());
let body = &analysis.bodies[0];
assert_eq!(body.status, BodyStatus::Parsed);
let source = body.source.as_ref().unwrap();
assert_eq!(source.text(), "eval('1');");
for finding in &body.findings {
    println!("{}: {}", finding.rule_id, &sql[finding.range.clone()]);
}
# Ok::<(), snowflake_bodies::Error>(())
```

JavaScript and Python are always available. Enable `java` and/or `scala` Cargo features for
the other parsers. With features disabled, extraction and position mapping still work; the
body reports `UnavailableLanguage`, with no tree or findings. Queries for all languages ship
regardless of features and are exposed by `Language::query()`.

This crate requires Rust 1.90 and supports tree-sitter 0.26 and 0.27. Consumers that exchange
trees must resolve the same tree-sitter version; `snowflake_bodies::tree_sitter` re-exports this
crate's resolved API. The grammar package retains its separate Rust 1.85 library floor.

## Source and measurement contract

`Analyzer` reuses its compiled parsers and queries across files. `analyze(&str)` returns the
SQL tree, SQL syntax-error ranges, extracted foreign-language bodies, and advisory findings.
Each body includes its name, routine kind, execution rights, SQL ranges, decoded source, parse
status, optional embedded tree, and mapped syntax errors. SQL-language bodies remain in the SQL
tree and are not returned a second time. No handler code is executed.

`BodySource::text()` excludes delimiters. Dollar bodies preserve every byte. Single-quoted
bodies decode doubled quotes and Snowflake backslash escapes, including three-digit ASCII octal,
two-digit ASCII hexadecimal, and four-digit Unicode escapes. Numeric escapes can cross the SQL grammar's child-node
boundaries, so the decoder consumes the complete content of the validated body node.
Malformed numeric escapes, non-ASCII byte escapes, and non-scalar Unicode values produce
`InvalidEncoding` rather than guessed text. Unknown nonnumeric escapes discard the backslash. Details are based on
[Snowflake's string specification](https://docs.snowflake.com/en/sql-reference/data-types-text).

Embedded tree offsets refer to decoded UTF-8 text. Map them with `source_offset` or
`source_range`; ranges are half-open and expand to include each original escape in full.
EOF maps immediately before the closing SQL delimiter. Invalid offsets/ranges return `None`.
`source_point` returns zero-based rows and UTF-8 byte columns, including CRLF and Unicode.
Call it on the original SQL text. Input must already be decoded to UTF-8: these offsets do
not refer to the original encoded bytes of a UTF-16 file.

Only `Parsed` bodies have successfully parsed embedded syntax. `InvalidBody` retains the
partial tree and mapped errors but skips restriction checking. `InvalidSql` and
`InvalidEncoding` have no reconstructed source; `UnavailableLanguage` has source but no tree.
Inspect `sql_errors` too: a malformed SQL header may prevent a routine from being recognized.
The current grammar also rejects a completely empty dollar body (`$$$$`); an empty single-quoted
body is recognized. This library preserves that grammar behavior and reports the SQL error.
None of these states means zero measured complexity. Consumers apply the appropriate language
profile and attribute the result to the enclosing SQL file exactly once. Vocabulary consumers
mask the decoded source with its language's own masking mode, then map findings back.

## Restriction catalog

These are bounded syntax checks, not an execution validator. `RULES` provides stable IDs,
messages, and severities. Warnings identify documented restrictions through literal syntax;
advisories identify proxies. All name-based matches require review because there is no symbol
resolution, alias tracking, type inference, interprocedural analysis, or constant propagation.
For example, a locally defined `eval` or `session.sql` can match, while an aliased API can escape
detection. A result with no findings is not a guarantee of runtime validity.

| Rules | Checked forms |
|---|---|
| `js-eval`, `js-import` | Direct `eval`/`require` calls, static and dynamic imports |
| `js-host-api` | Direct calls/construction of selected browser/network APIs; advisory |
| `python-process` | Literal `subprocess`, `multiprocessing`, and `os` process-creation calls |
| `concurrency` | Selected thread/executor/future constructors, Java parallel streams, Scala `.par`; advisory |
| `session-builder`, `jdbc-connection` | Java/Scala `Session.builder` and JDBC access; builder use is advisory |
| `python-put-get` | PUT/GET statements in a literal passed directly to `.sql(...)` |
| `python-get-pattern` | Glob metacharacters in a literal first argument to `.file.get(...)` |
| `local-write-path` | Java/Scala literal GET destinations and direct file-download destinations outside `/tmp` |
| `owner-temp-object` | Temporary-object DDL in literal `.sql(...)` under explicit/default owner rights |
| `scala-task-warehouse` | A task without a warehouse calling a uniquely named, equally qualified Scala procedure in the same file; advisory |

The embedded `.scm` files select syntax and name predicates. Literal SQL is parsed with the
Snowflake grammar for transfer and temporary-object checks; it is not searched as text.
Those findings cover the containing string literal in the original SQL file. Unsupported
embedded string escapes, interpolation, concatenation, variable SQL, malformed literal SQL,
external files, and indirect calls are not followed. Path checks normalize `.` and `..` but
cannot resolve symbolic links. PUT reads a local source; its source path is not treated as a
local write. Task checks do not resolve session database/schema context or external declarations.

Snowpark restrictions apply to procedures, not UDFs. The temporary-object rule is scoped to
Python/Java/Scala procedures, where the referenced documentation states it, rather than applying
it to SQL scripting indiscriminately. Runtime resource limits, memory exhaustion, general
network/disk behavior, arbitrary concurrency, and server configuration cannot be established by
these checks. See the official [JavaScript](https://docs.snowflake.com/en/developer-guide/stored-procedure/stored-procedures-javascript),
[Python](https://docs.snowflake.com/en/developer-guide/stored-procedure/python/procedure-python-limitations),
[Java](https://docs.snowflake.com/en/developer-guide/stored-procedure/java/procedure-java-limitations), and
[Scala](https://docs.snowflake.com/en/developer-guide/stored-procedure/scala/procedure-scala-limitations)
references (checked 2026-09-11).

## Verification

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace
cargo test -p snowflake-bodies --all-features
cargo run -p snowflake-bodies --example summary -- /path/to/local/sql
```

CI also builds and tests both workspace members with tree-sitter pinned to 0.26. Synthetic
tests cover decoding and location mapping, parse failures, disabled features, positive and
negative rule cases, caller/owner rights, functions, and task context.

The grammar crate must be published before this companion can resolve its registry dependency.
Publishing either package is a separate release operation.
