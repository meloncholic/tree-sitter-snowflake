# Consumer integration

What `cadence`, `marlin`, and `clause` each need to do with this grammar. The companion
[`snowflake-bodies`](../snowflake-bodies/README.md) crate provides shared foreign-body extraction,
position mapping, parsing, and advisory restriction checks. Profiles, dialect selection, masking,
and metric attribution remain consumer responsibilities.

## cadence

`cadence` registers each language as a `LanguageProfile`: a struct naming the grammar's entry
point plus the node kinds that mean "function", "decision point", "closure", "name", "parameters",
and "body". Add a Snowflake constant alongside the existing SQL one:

| Field | Value |
|---|---|
| `block_kinds` | `create_procedure`, `create_function` (and their `alter_procedure`/`alter_function` spellings), each `BlockKind::Function` |
| `decision_kinds` | `if_statement`, `elseif_clause`, `case_statement`, `while_statement`, `for_statement`, `repeat_statement`, `loop_statement`, `exception_handler` |
| `closure_kinds` | empty — Snowflake SQL has no closure form |
| `name_node_kind` | `object_reference` |
| `parameter_node_kind` | `function_arguments` |
| `body_node_kind` | `function_body` |
| `body_is_self` | `false` |

`object_reference`, `function_arguments`, and `function_body` deliberately match the names the
T-SQL profile already uses, so the traversal code's existing handling for grammars that expose
these as plain named children rather than fields applies unchanged.

`cadence` also needs a `Snowflake` variant reachable from its per-path dialect glob mapping (see
"Dialect selection" below) and integration with `snowflake-bodies` (see "Foreign-language
bodies" below). The companion uses the JavaScript/Python grammar versions already linked by
`cadence`; it adds no new embedded language unless Java or Scala is enabled.

`cadence`'s language profiles, structural traversal, and masking logic are kept in sync with
`marlin`'s equivalents by hand, with no dependency between the repositories. A Snowflake profile
change is therefore a two-repository change and should be reviewed as one.

## marlin

Two integrations.

**Structural profile.** The same shape as `cadence`'s table above, in `marlin`'s own registry,
plus a `Snowflake` variant reachable from the per-path dialect glob mapping (see "Dialect
selection" below) and a new arm in the profile lookup.

**Masking spec.** `marlin` masks comments and string literals before running vocabulary rules, so
that a banned word inside a string is not reported as prose. The existing `Sql` mode assumes ANSI
rules — `--`/`/* */` comments, single-quoted strings escaped by doubling the quote — which is
wrong for Snowflake in three ways a Snowflake-specific mode has to cover:

- `//` also starts a line comment, alongside `--` and `/* */`.
- `$$ ... $$` delimits a string that spans lines and contains anything.
- Snowflake accepts backslash escapes inside single-quoted strings in addition to doubled quotes.

A JavaScript procedure body is neither prose nor a SQL string literal: masking it wholesale hides
real identifiers and comments from the vocabulary rules, while masking none of it runs SQL-shaped
rules over JavaScript. Hand the body's range to the JavaScript masking mode `marlin` already has,
and fall back to masking it entirely only where no mode matches the declared language.

`marlin` has an existing test asserting that every extension claiming a structural profile also
has a real code/comment-splitting masking mode — the backstop for the rule above, but only if the
Snowflake dialect actually reaches it. Check the dialect-keyed lookup wiring directly rather than
assuming the test covers it.

## clause

**Decision: Reading A — this grammar is a testing oracle for `clause`, not a runtime parser.**

`clause` deliberately does not use tree-sitter (its own lexer and syntax tree, for a lossless tree
with exact spans and error recovery good enough to format a file safely) and its Snowflake dialect
today fails closed with exit code 2. `clause` writes its own Snowflake lexer and parser when it
gets to that dialect, exactly as it did for T-SQL, and uses this grammar for differential testing:
parse the same corpus with both, and report where they disagree about statement boundaries or
where one produces errors the other does not. This grammar is a development dependency for
`clause`, not a runtime one.

The reasoning `clause` already used to reject `tree-sitter-sequel-tsql` for T-SQL (it needs a
lossless tree, exact spans, and format-safe error recovery — properties of how `clause` wants to
build a formatter, not properties of any one dialect) applies to Snowflake identically. Adopting a
tree-sitter grammar as the runtime Snowflake parser instead would reopen that already-settled
question for one dialect only, and leave `clause` maintaining two different parsing architectures
indefinitely. This is revisitable by whoever owns `clause` if the cost of writing a third
hand-written parser from scratch proves prohibitive when `clause` actually reaches its Snowflake
milestone — that is a real cost, and a legitimate reason to reconsider with an actual effort
estimate in hand, but not a reason to decide differently now.

`clause`'s Snowflake work is scheduled after its T-SQL parity milestone, so this is the least
urgent of the three integrations. The concrete deliverable when that work starts is a small
`clause`-facing harness plus a shared corpus, not an API — and `clause` needs the same per-path
dialect glob mapping described below, since it selects a parser by extension the same way
`cadence` and `marlin` do.

## Dialect selection

Snowflake and T-SQL are both written in files ending `.sql`, and nothing in the extension
distinguishes them. Content sniffing — guessing the dialect from keywords in the file — is
rejected: it fails silently in both directions, makes a file's measurement depend on its contents
in a way nobody can predict from configuration, and the failure looks like a tool bug rather than
a misconfiguration.

**Decision: all three consumers (`cadence`, `marlin`, `clause`) select a dialect by a configured
per-path glob mapping — not a single repository-wide setting.** A glob mapping (e.g. `snowflake/**`
→ `Snowflake`, everything else → the prior default) handles both the common single-dialect repo
and a repo that holds both dialects with the same mechanism, so there's no later migration from a
repo-wide setting to a glob one: a single-dialect repo just configures one catch-all pattern.
`marlin` already has a `sql_dialect` setting (`Tsql`/`Postgres`) that applies repo-wide — widen it
to a glob mapping rather than adding `Snowflake` as one more value on the existing repo-wide enum.
`cadence` has no dialect setting yet, so build the glob form directly. `clause` needs the same
per-path selection regardless of which reading of "Consumer: clause" above it settles on.

## Foreign-language bodies

Use `snowflake_bodies::Analyzer` to obtain reconstructed source and embedded trees instead of
duplicating body decoding. Inspect both `Analysis::sql_errors` and each `Body::status`; only
`Parsed` means the embedded syntax parsed successfully. Map embedded byte ranges with
`BodySource::source_range`, and pass the resulting SQL byte offset to `source_point` for a
zero-based row and byte column. `Body::findings` already contains absolute SQL ranges.
Reuse the analyzer across files. Enable the `java` or `scala` features when those languages are
needed; otherwise they explicitly report `UnavailableLanguage` while retaining decoded source.
The crate does not calculate complexity or implement vocabulary masking. Its queries and rule
catalog are reusable independently, with detection limits documented in its README.

The following describes the source and attribution contract implemented by that shared API.

A Snowflake procedure or function's `language` field names `SQL`, `JAVASCRIPT`, `PYTHON`, `JAVA`,
or `SCALA`. Only `SQL` is parsed by this grammar; the rest are a different language carried inside
the body. The shared crate finds the body node, reads the `language` field, reconstructs its
source, and dispatches the corresponding embedded grammar. The resulting tree is measured under that
language's own existing profile — both `cadence` and `marlin` already have one for JavaScript and
Python, which is every foreign-language body in the org's corpus today and the most likely next
one. Java and Scala are available through optional features; neither appears in the measured corpus.

The two body delimiter forms need different handling, and the corpus this grammar was built
against uses the harder one almost exclusively:

- **Dollar-quoted (`$$ ... $$`, node kinds `dollar_quoted_body`/`dollar_quoted_script`/
  `dollar_quoted_expression`).** The content node's byte range *is* the embedded language's
  source. Parse it directly (`Parser::set_included_ranges`, or slice the bytes and parse the
  slice). `queries/injections.scm` already expresses this for an editor host.
- **Single-quoted (`AS '...'`, node kind `string_body`).** `''` in the file is one apostrophe in
  the embedded language, so the byte range is *not* the source — positions inside it do not line
  up with positions in the file, and tree-sitter's injection mechanism cannot reach it (it parses
  a range of the original source with no unescaping step). The grammar exposes every `''` as a
  `doubled_quote` node and every backslash escape as an `escape` node inside the content, so a
  shared crate reconstructs the real text, collapsing each
  `doubled_quote` to a single `'` and each `escape` to its escaped character, and records an
  offset table mapping positions in the reconstructed string back to byte positions in the
  original file. Numeric escapes may span multiple content nodes. It parses the reconstructed
  text with the target language's grammar; consumers use the
  offset table to translate any finding's position back to a real file location before reporting
  it.

**Where a language has no linked grammar (Java/Scala when their features are disabled), report the body as unmeasured, never
as measured-at-zero.** A body that is present but excluded from measurement is a known,
communicable gap; a body silently counted as empty is a wrong number that looks like a clean file.
This is also the fix for `marlin`'s existing PostgreSQL/plpgsql body handling, which exhibits the
same failure in a different language today.

**Decision: a foreign-language body's complexity is attributed to the SQL file, never to a
separate language-profile total, and never to both.** Measure the body under the embedded
language's own metrics (its decision points, its nesting), but roll that measurement into the
enclosing procedure's — and therefore the SQL file's — totals, the same as any other function
body. Counting it under both totals double-counts it: `cadence`/`marlin` totals are additive (sum
of functions, repo-wide averages), so double-counting inflates every aggregate metric derived from
them and can produce duplicate lint findings from two structural passes over the same text.
Counting it only under a generic JavaScript-profile total is the subtler mistake — there is no
real ambient "JavaScript file" here to attribute to, so that bucket would quietly mix counts that
actually came from `.sql` files into whatever a repo-wide "how much JavaScript do we have" report
is meant to measure. Apply this identically in `cadence` and `marlin`, since their profiles are
kept in sync by hand rather than shared code.

## Node kinds are the public API

Consumers hold string literals — `"create_procedure"`, `"object_reference"`, `"function_body"` —
in configuration tables and compare node kinds against those strings at runtime, not a typed AST.
A grammar change that renames or removes a node kind compiles cleanly everywhere and produces
wrong measurements silently: the block simply stops being recognized, and the file measures as
though it contained nothing. `test/node-kinds.txt` is the committed, CI-diffed snapshot that makes
such a change visible in review; a removal or rename is always a major version bump. Re-run
`node tools/node-kinds.mjs` after upgrading and diff it against the previous release's snapshot
before wiring a new profile, rather than assuming names carried over.

## Before adopting a release

Build this crate against the exact `tree-sitter` version the consumer pins, and run the consumer's
own test/fixture suite against the new version before merging the bump. Neither consumer should
first discover a breaking node-kind change in its own CI.

This crate's own `tree-sitter` dependency is a dev-dependency and tracks the newest release (0.27
today); the published crate's only runtime dependency is `tree-sitter-language`, so the consumer's
own `tree-sitter` version governs at their end. The `consumer-pin` job in
`.github/workflows/verify.yml` rebuilds against 0.26 — what `cadence` and `marlin` both declare,
resolved as `>=0.26, <0.27` — so the two jobs together cover the range in actual use. The generated
parser declares ABI 15, which both versions accept.

Two version lines are easy to conflate. The `tree-sitter` **crate** and the `tree-sitter-cli` **npm
package** share a version line (both publish 0.26.x and 0.27.0); the `tree-sitter` **npm package**,
the Node runtime binding this repo declares as an optional peer, is a separate line whose latest
release is 0.25.1. There is no 0.26 of it to move to, and its version carries no implication for
the crate's.
