((instance_expression (type_identifier) @type) @concurrency
 (#eq? @type "Thread"))
((call_expression function: (_) @target) @concurrency
 (#match? @target "(^|\\.)(Future|parallelStream|newFixedThreadPool|newCachedThreadPool|newSingleThreadExecutor)$"))
((field_expression field: (identifier) @field) @concurrency
 (#eq? @field "par"))
((call_expression function: (field_expression value: (identifier) @object field: (identifier) @method)) @session-builder
 (#eq? @object "Session") (#eq? @method "builder"))
((field_expression field: (identifier) @field) @jdbc-connection
 (#eq? @field "jdbcConnection"))
((call_expression function: (field_expression field: (identifier) @method)
 arguments: (arguments . (string) @sql))
 (#eq? @method "sql"))
((call_expression function: (field_expression value: (field_expression field: (identifier) @file) field: (identifier) @method)
 arguments: (arguments (string) (string) @local-path))
 (#eq? @file "file") (#eq? @method "get"))
