((object_creation_expression type: (_) @type) @concurrency
 (#match? @type "(^|\\.)(Thread|ThreadPoolExecutor|ScheduledThreadPoolExecutor|ForkJoinPool)$"))
((method_invocation name: (identifier) @method) @concurrency
 (#match? @method "^(parallelStream|supplyAsync|runAsync|newFixedThreadPool|newCachedThreadPool|newSingleThreadExecutor|newScheduledThreadPool)$"))
((method_invocation object: (identifier) @object name: (identifier) @method) @session-builder
 (#eq? @object "Session") (#eq? @method "builder"))
((method_invocation name: (identifier) @method) @jdbc-connection
 (#eq? @method "jdbcConnection"))
((field_access field: (identifier) @field) @jdbc-connection
 (#eq? @field "jdbcConnection"))
((method_invocation name: (identifier) @method arguments: (argument_list . (string_literal) @sql))
 (#eq? @method "sql"))
((method_invocation object: (method_invocation name: (identifier) @file)
 name: (identifier) @method arguments: (argument_list (string_literal) (string_literal) @local-path))
 (#eq? @file "file") (#eq? @method "get"))
