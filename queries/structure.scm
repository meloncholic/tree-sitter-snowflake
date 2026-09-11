; Structure query: the block, decision, name, parameter and body captures
; measurement and linting tools (cadence, marlin) consume. The node names
; pinned here are the grammar's public API — create_procedure,
; create_function, if_statement, elseif_clause, case_statement,
; while_statement, for_statement, repeat_statement, loop_statement,
; exception_handler, object_reference, function_arguments, function_body.

; --- blocks: the function-like definitions -------------------------------

(create_procedure
  name: (object_reference) @definition.name
  (function_arguments) @definition.parameters
  body: (function_body) @definition.body) @definition.block

(create_function
  name: (object_reference) @definition.name
  (function_arguments) @definition.parameters
  body: (function_body) @definition.body) @definition.block

(alter_procedure
  name: (object_reference) @definition.name
  (function_arguments) @definition.parameters
  body: (function_body) @definition.body) @definition.block

(alter_function
  name: (object_reference) @definition.name
  (function_arguments) @definition.parameters
  body: (function_body) @definition.body) @definition.block

; --- decisions: Snowflake Scripting control flow -------------------------

(if_statement) @decision
(elseif_clause) @decision
(case_statement) @decision
(case_when_clause) @decision
(while_statement) @decision
(for_statement) @decision
(repeat_statement) @decision
(loop_statement) @decision
(exception_handler) @decision

; --- bodies ---------------------------------------------------------------

(dollar_quoted_script) @body
(dollar_quoted_expression) @body
(dollar_quoted_body) @foreign.body
(string_body) @foreign.body
