; Syntax highlighting for Snowflake SQL.

(object_reference
  name: (identifier) @type)

(invocation
  (object_reference
    name: (identifier) @function.call))

(cast
  name: [(keyword_cast) (keyword_try_cast)] @function.call)

(identifier_function (keyword_identifier) @function.call)

(relation
  alias: (identifier) @variable)

(field
  name: (identifier) @field)

(term
  alias: (identifier) @variable)

(rename_pair
  alias: (identifier) @variable)

(stage_reference) @special

(literal) @string
(comment) @comment @spell
(marginalia) @comment

(body_content) @string
(doubled_quote) @string.escape
(escape) @string.escape

((literal) @number
   (#match? @number "^[-+]?%d+$"))

((literal) @float
   (#match? @float "^[-+]?%d*\.%d*$"))

[
  (keyword_asc)
  (keyword_desc)
  (keyword_default)
  (keyword_collate)
  (keyword_autoincrement)
  (keyword_enforced)
  (keyword_rely)
  (keyword_preceding)
  (keyword_following)
  (keyword_unbounded)
  (keyword_current)
  (keyword_nulls)
  (keyword_first)
  (keyword_last)
  (keyword_distinct)
  (keyword_top)
  (keyword_exclude)
  (keyword_rename)
] @attribute

[
  (keyword_case)
  (keyword_when)
  (keyword_then)
  (keyword_else)
  (keyword_end)
  (keyword_if)
  (keyword_elseif)
  (keyword_while)
  (keyword_for)
  (keyword_do)
  (keyword_repeat)
  (keyword_until)
  (keyword_loop)
  (keyword_break)
  (keyword_continue)
  (keyword_return)
  (keyword_raise)
  (keyword_begin)
  (keyword_declare)
  (keyword_let)
  (keyword_exception)
  (keyword_open)
  (keyword_close)
  (keyword_fetch)
  (keyword_resultset)
  (keyword_execute)
  (keyword_immediate)
] @keyword

[
  (keyword_select)
  (keyword_insert)
  (keyword_update)
  (keyword_delete)
  (keyword_merge)
  (keyword_into)
  (keyword_values)
  (keyword_with)
  (keyword_recursive)
  (keyword_from)
  (keyword_where)
  (keyword_group)
  (keyword_by)
  (keyword_having)
  (keyword_qualify)
  (keyword_order)
  (keyword_limit)
  (keyword_offset)
  (keyword_union)
  (keyword_except)
  (keyword_minus)
  (keyword_intersect)
  (keyword_join)
  (keyword_inner)
  (keyword_left)
  (keyword_right)
  (keyword_full)
  (keyword_outer)
  (keyword_cross)
  (keyword_lateral)
  (keyword_on)
  (keyword_using)
  (keyword_as)
  (keyword_pivot)
  (keyword_unpivot)
  (keyword_window)
  (keyword_over)
  (keyword_partition)
  (keyword_rows)
  (keyword_range)
  (keyword_within)
  (keyword_grouping)
  (keyword_sets)
  (keyword_cube)
  (keyword_rollup)
] @keyword

[
  (keyword_create)
  (keyword_or)
  (keyword_replace)
  (keyword_alter)
  (keyword_drop)
  (keyword_add)
  (keyword_column)
  (keyword_modify)
  (keyword_table)
  (keyword_view)
  (keyword_materialized)
  (keyword_dynamic)
  (keyword_secure)
  (keyword_transient)
  (keyword_temporary)
  (keyword_volatile)
  (keyword_external)
  (keyword_if)
  (keyword_exists)
  (keyword_cluster)
  (keyword_procedure)
  (keyword_function)
  (keyword_returns)
  (keyword_language)
  (keyword_task)
  (keyword_stage)
  (keyword_file)
  (keyword_format)
  (keyword_stream)
  (keyword_pipe)
  (keyword_warehouse)
  (keyword_database)
  (keyword_schema)
  (keyword_role)
  (keyword_user)
  (keyword_sequence)
  (keyword_tag)
  (keyword_integration)
  (keyword_clone)
  (keyword_swap)
  (keyword_copy)
  (keyword_grants)
  (keyword_grant)
  (keyword_revoke)
  (keyword_privileges)
  (keyword_future)
  (keyword_share)
  (keyword_public)
  (keyword_to)
  (keyword_from)
  (keyword_all)
  (keyword_call)
  (keyword_show)
  (keyword_describe)
  (keyword_use)
  (keyword_set)
  (keyword_unset)
  (keyword_put)
  (keyword_get)
  (keyword_list)
  (keyword_remove)
  (keyword_start)
  (keyword_transaction)
  (keyword_commit)
  (keyword_rollback)
  (keyword_work)
  (keyword_resume)
  (keyword_suspend)
  (keyword_abort)
  (keyword_queries)
  (keyword_after)
  (keyword_when)
  (keyword_schedule)
] @keyword

[
  (keyword_null)
  (keyword_true)
  (keyword_false)
  (keyword_not)
  (keyword_and)
  (keyword_or)
  (keyword_in)
  (keyword_is)
  (keyword_like)
  (keyword_ilike)
  (keyword_regexp)
  (keyword_rlike)
  (keyword_between)
  (keyword_exists)
  (keyword_interval)
] @keyword.operator

[
  (keyword_sql)
  (keyword_javascript)
  (keyword_python)
  (keyword_java)
  (keyword_scala)
] @type

[
  (keyword_number)
  (keyword_int)
  (keyword_float)
  (keyword_double)
  (keyword_double_prec_only)
  (keyword_boolean)
  (keyword_char)
  (keyword_varchar)
  (keyword_string)
  (keyword_binary)
  (keyword_date)
  (keyword_datetime)
  (keyword_time)
  (keyword_timestamp)
  (keyword_variant)
  (keyword_object)
  (keyword_array)
  (keyword_geography)
  (keyword_geometry)
  (keyword_vector)
] @type.builtin

[
  (keyword_primary)
  (keyword_key)
  (keyword_unique)
  (keyword_foreign)
  (keyword_references)
  (keyword_constraint)
  (keyword_masking)
  (keyword_policy)
] @attribute

[
  "::"
  "||"
  "=>"
  ":="
] @operator

(bind_variable) @variable.parameter

(named_argument
  name: (identifier) @parameter)

(function_argument
  name: (identifier) @parameter)
