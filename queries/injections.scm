; Foreign-language procedure and function bodies.
;
; Each supported language gets its own branch, naming the lowercase
; tree-sitter grammar name explicitly rather than deriving it from the
; captured keyword (Snowflake spells it JAVASCRIPT; tree-sitter resolves
; grammars as `javascript`). A host that has not linked a grammar simply
; does not inject — the tree shape never depends on what the host has.
;
; Only the dollar-quoted body is injectable: tree-sitter parses a range
; of the original source, and the single-quoted body's `''` doubling
; means its byte range is not the embedded language's source. Those
; bodies (the common single-quoted form for foreign-language bodies) are
; reconstructed by the consumer: collapse the `doubled_quote` and
; `escape` nodes, then parse the result with a position-mapping table.
; See docs/consumer-integration.md.

((create_procedure
   (foreign_language (keyword_javascript))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "javascript"))

((create_procedure
   (foreign_language (keyword_python))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "python"))

((create_procedure
   (foreign_language (keyword_java))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "java"))

((create_procedure
   (foreign_language (keyword_scala))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "scala"))

((create_function
   (foreign_language (keyword_javascript))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "javascript"))

((create_function
   (foreign_language (keyword_python))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "python"))

((create_function
   (foreign_language (keyword_java))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "java"))

((create_function
   (foreign_language (keyword_scala))
   body: (function_body (dollar_quoted_body) @injection.content))
 (#set! injection.language "scala"))
