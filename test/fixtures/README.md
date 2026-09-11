# Test fixtures

Whole-file Snowflake sources, one construct family per file, parsed by
`tools/fixture-check.mjs` on every change (zero `ERROR`/`MISSING` nodes and
zero zero-width nodes required; see that script). The corpus tests in
`test/corpus/` assert exact tree shapes; these files assert that realistic
whole files parse end to end, which is also the shape the parse-rate
baseline is measured against.

## Scrubbing

Fixtures are fully synthetic. Identifiers follow a short generic scheme —
`DB1`/`DB2` (databases), `S1`/`S2`/`S3` (schemas), `T1`..`T6` (tables),
`V1`/`V2` (views), `C1`..`C7` (`"Col_A"` where a quoted spelling is part of
the construct), `P1`..`P5` (procedures), `F1`..`F3` (functions),
`TASK1`..`TASK3`, `ROLE1`/`ROLE2`, `WH1`, `STG1`, `FF1`, `INT1`, `STRM1`,
`PIPE1`, `SEQ1`, `TAG1`, `SL1`, `AGENT1`, `SEMV1` — so nothing in this
directory resembles a real warehouse. `tools/fixture-leak-grep.mjs` asserts
that: it greps every fixture for the identifiers and names observed in the
source repositories the shapes were mined from, and fails on any hit. Run
it whenever a fixture is added or edited.

A fixture parsing clean is not proof it is valid Snowflake — a parser has
no semantic layer. Shapes not verified against a real engine are marked
*docs-derived* below.

## Files

| Fixture | Constructs |
|---|---|
| `use_and_session.sql` | `USE DATABASE/SCHEMA/ROLE/WAREHOUSE`, `USE SECONDARY ROLES ALL`, `SET`/`UNSET` session variables |
| `database_schema.sql` | `CREATE DATABASE`/`SCHEMA` with comments and grants |
| `table_quoted_columns_constraints.sql` | `TRANSIENT TABLE`, quoted column names, column comments, `RELY` constraints, table `COMMENT=`, grant verbs incl. `EVOLVE SCHEMA`, `SELECT ERROR TABLE` |
| `table_column_options.sql` | `AUTOINCREMENT START/INCREMENT/NOORDER`, `DEFAULT` (literal, `FALSE`, `CURRENT_TIMESTAMP()`), `ARRAY`/`VARIANT` columns, foreign key |
| `view_column_list.sql` | view column list, `IFNULL`, `CASE`, `ORDER BY` in a view, `SECURE VIEW` |
| `materialized_dynamic_tables.sql` | `MATERIALIZED VIEW`; `DYNAMIC TABLE` with `TARGET_LAG`/`WAREHOUSE` (docs-derived) |
| `file_format_and_stage.sql` | `FILE FORMAT` options, external `STAGE` (`URL`, `STORAGE_INTEGRATION`, `FILE_FORMAT = db.schema.ff`), stage/file-format grants |
| `stream_and_pipe.sql` | `STREAM ON TABLE`; `PIPE ... AS COPY INTO t (cols) FROM (SELECT $1, $2 FROM @stage/path)` (docs-derived) |
| `warehouse_options.sql` | warehouse option flood incl. identifier-valued `SCALING_POLICY=STANDARD` |
| `storage_integration.sql` | `STORAGE INTEGRATION` with `STORAGE_ALLOWED_LOCATIONS=('azure://...')` |
| `role_grants.sql` | `CREATE ROLE IF NOT EXISTS`, role hierarchy, schema-scope privileges incl. `MASKING POLICY`, `ZEROCOPY CONNECTOR`, future grants, `REVOKE` |
| `comment_on.sql` | `COMMENT ON TABLE/COLUMN/VIEW/PROCEDURE` |
| `cortex_agent.sql` | `CREATE AGENT` with `profile='json'` and `FROM SPECIFICATION $$yaml$$` |
| `semantic_view.sql` | `SEMANTIC VIEW` — tables/facts/dimensions/metrics sections, `WITH SYNONYMS`, `AI_SQL_GENERATION` |
| `task_cron_call.sql` | task `WAREHOUSE=`, `SCHEDULE='USING CRON ...'`, `AS CALL`, task grants |
| `task_after_when.sql` | task `AFTER` dependency, `WHEN SYSTEM$STREAM_HAS_DATA(...)` (docs-derived) |
| `procedure_sql_string_body.sql` | `LANGUAGE SQL` procedure, single-quoted body with `''` doubling |
| `procedure_js_string_body.sql` | `LANGUAGE JAVASCRIPT` procedure, single-quoted body: JS template literals, `''` doubling, try/catch |
| `procedure_scripting_dollar.sql` | `$$` scripting: `DECLARE`, `SELECT INTO`, `MERGE`, `SQLROWCOUNT`, `EXCEPTION WHEN OTHER`, `LET`, `RAISE` |
| `procedure_cursor_named_exception.sql` | cursor `FOR` loop, named `EXCEPTION (-20101, '..')`, nested blocks with handlers, `CONTINUE`, `EXECUTE IMMEDIATE` on concatenated text |
| `procedure_resultset_stream.sql` | `RESULTSET DEFAULT (SELECT ...)`, `FOR ... IN resultset` (docs-derived) |
| `function_sql_string_body.sql` | scalar SQL UDF, single-quoted body, quadrupled `''''` in `REGEXP_REPLACE` patterns |
| `function_sql_dollar_comment.sql` | SQL UDF, `$$` body, `COMMENT =` before `AS` |
| `function_python.sql` | Python UDF: `RUNTIME_VERSION`, `HANDLER`, `PACKAGES` (docs-derived) |
| `merge_statement.sql` | `MERGE` with aggregate `USING`, `WHEN MATCHED AND (...) THEN UPDATE`, `WHEN NOT MATCHED THEN INSERT` |
| `insert_overwrite.sql` | `INSERT OVERWRITE INTO t (cols) WITH cte ...` inside a scripting block |
| `select_cte_window_qualify.sql` | `WITH RECURSIVE`, window functions incl. nested aggregate `SUM(SUM(x)) OVER`, `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, `QUALIFY` |
| `select_grouping_sets.sql` | `GROUP BY GROUPING SETS` incl. the empty set `()` |
| `select_pivot_unpivot.sql` | `PIVOT`/`UNPIVOT` (docs-derived) |
| `select_semi_structured_flatten.sql` | `:` paths with `::` casts, `[0]` subscripts, `LATERAL FLATTEN(input => ...)` (docs-derived) |
| `select_match_recognize.sql` | `MATCH_RECOGNIZE` with `MEASURES`, `ONE ROW PER MATCH`, `AFTER MATCH SKIP PAST LAST ROW`, `PATTERN`, `DEFINE` |
| `transaction_alter_admin.sql` | `BEGIN TRANSACTION`/`COMMIT`, `BEGIN WORK`/`ROLLBACK`, `ALTER ACCOUNT SET`, `ALTER TABLE ADD COLUMN`, `ALTER TASK RESUME`, `ALTER WAREHOUSE SUSPEND/SET` |
| `copy_put_get_list_remove.sql` | `COPY INTO` both directions with `FILE_FORMAT = (...)`, `PATTERN`, `HEADER`; `PUT`/`GET` with `file://`, `LIST`, `REMOVE` |
| `show_describe_call.sql` | `SHOW TABLES [TERSE VIEWS] ... LIKE/IN`, `DESC TABLE/PROCEDURE/FUNCTION`, `CALL` positional and `=>` named arguments |

## Commands

```bash
node tools/fixture-check.mjs       # parse every fixture; fail on ERROR/MISSING/zero-width
node tools/fixture-leak-grep.mjs   # fail on any source-corpus identifier
```
