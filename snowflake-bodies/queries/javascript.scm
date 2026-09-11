; Capture names identify public rules. Name-based findings require human review.
((call_expression function: (identifier) @target) @js-eval
 (#eq? @target "eval"))
((call_expression function: (identifier) @target) @js-import
 (#eq? @target "require"))
(import_statement) @js-import
(call_expression function: (import)) @js-import
((call_expression function: (identifier) @target) @js-host-api
 (#match? @target "^(fetch|XMLHttpRequest|WebSocket)$"))
((new_expression constructor: (identifier) @target) @js-host-api
 (#match? @target "^(XMLHttpRequest|WebSocket)$"))
