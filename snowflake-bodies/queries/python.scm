((call function: (attribute object: (identifier) @module attribute: (identifier) @method)) @python-process
 (#eq? @module "subprocess")
 (#match? @method "^(Popen|run|call|check_call|check_output)$"))
((call function: (attribute object: (identifier) @module attribute: (identifier) @method)) @python-process
 (#eq? @module "multiprocessing")
 (#match? @method "^(Process|Pool)$"))
((call function: (attribute object: (identifier) @module attribute: (identifier) @method)) @python-process
 (#eq? @module "os")
 (#match? @method "^(system|popen|fork|forkpty|posix_spawn|posix_spawnp|spawnl|spawnle|spawnlp|spawnlpe|spawnv|spawnve|spawnvp|spawnvpe)$"))
((call function: (_) @target) @concurrency
 (#match? @target "^(threading\\.Thread|concurrent\\.futures\\.(ThreadPoolExecutor|ProcessPoolExecutor))$"))
; Only literal SQL passed to a sql method is inspected; dataflow is not inferred.
((call function: (attribute attribute: (identifier) @method)
 arguments: (argument_list . (string) @sql))
 (#eq? @method "sql"))
((call function: (attribute object: (attribute attribute: (identifier) @file) attribute: (identifier) @method)
 arguments: (argument_list . (string) @stage-path))
 (#eq? @file "file") (#eq? @method "get"))
