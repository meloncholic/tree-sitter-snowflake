// External scanner for tree-sitter-snowflake.
//
// Its only job is the dollar-quoted string (`$$ ... $$`): the content can
// contain anything, including the grammar's own operators and unbalanced
// quotes, so no regular expression can match it. Adapted from
// DerekStride/tree-sitter-sql's scanner (MIT, copyright 2021 Derek
// Stride) — see NOTICE.
//
// Snowflake supports only the bare `$$` delimiter, not PostgreSQL's
// `$tag$` form (verified against Snowflake's documentation), so this
// scanner carries no tag state and needs no serialization.
//
// Three tokens, produced only where the grammar declares them valid:
//
//   DOLLAR_QUOTE_START   the opening `$$`
//   DOLLAR_QUOTE_CONTENT the raw text up to the closing `$$` — valid only
//                        inside a foreign-language body and inside an
//                        ordinary dollar-quoted string literal, where the
//                        whole span is one opaque node
//   DOLLAR_QUOTE_END     the closing `$$`
//
// A `LANGUAGE SQL` body does NOT use the content token: the grammar
// parses statements between the delimiters, so the scanner is simply
// never called with CONTENT valid there, and the statements lex
// normally.
//
// When both START and END are valid at one position — a nested `$$` body
// inside a `$$` script (EXECUTE IMMEDIATE $$ CREATE PROCEDURE ...
// LANGUAGE JAVASCRIPT AS $$ ... $$ ... $$) — START is checked first and
// wins, which is always the correct reading: the outer end tag is only
// reachable where a new statement could start, and no Snowflake
// statement begins with `$`.
#include "tree_sitter/parser.h"
#include <wctype.h>

enum TokenType {
  DOLLAR_QUOTE_START,
  DOLLAR_QUOTE_CONTENT,
  DOLLAR_QUOTE_END,
};

void *tree_sitter_snowflake_external_scanner_create(void) { return NULL; }
void tree_sitter_snowflake_external_scanner_destroy(void *payload) { (void)payload; }
unsigned tree_sitter_snowflake_external_scanner_serialize(void *payload, char *buffer) {
  (void)payload;
  (void)buffer;
  return 0;
}
void tree_sitter_snowflake_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  (void)payload;
  (void)buffer;
  (void)length;
}

static inline bool is_space(int32_t c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f' || c == '\v';
}

// Matches a bare `$$` at the current position.
static bool scan_dollar_dollar(TSLexer *lexer) {
  if (lexer->lookahead != '$') {
    return false;
  }
  lexer->advance(lexer, false);
  if (lexer->lookahead != '$') {
    return false;
  }
  lexer->advance(lexer, false);
  lexer->mark_end(lexer);
  return true;
}

bool tree_sitter_snowflake_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  (void)payload;

  if (valid_symbols[DOLLAR_QUOTE_START]) {
    while (is_space(lexer->lookahead)) {
      lexer->advance(lexer, true);
    }
    if (scan_dollar_dollar(lexer)) {
      lexer->result_symbol = DOLLAR_QUOTE_START;
      return true;
    }
  }

  if (valid_symbols[DOLLAR_QUOTE_END]) {
    while (is_space(lexer->lookahead)) {
      lexer->advance(lexer, true);
    }
    if (scan_dollar_dollar(lexer)) {
      lexer->result_symbol = DOLLAR_QUOTE_END;
      return true;
    }
  }

  if (valid_symbols[DOLLAR_QUOTE_CONTENT]) {
    // The content starts exactly where the opening delimiter ended —
    // leading whitespace belongs to the content, so nothing is skipped
    // and every byte between the delimiters lands in the token. A lone
    // `$` (a `$1` positional reference, a `$var` in reconstructed
    // JavaScript, `$1***$2` in a regex replacement) is part of the
    // content: only an adjacent `$` pair closes it. An empty run (`$$`
    // immediately followed by `$$`) returns false so the grammar's
    // optional-content alternative can reduce instead — a zero-width
    // token is not a thing the parser accepts.
    bool advanced = false;
    while (true) {
      if (lexer->eof(lexer)) {
        return false;
      }
      if (lexer->lookahead == '$') {
        // Tentatively end the token before this `$`; if the next byte is
        // also `$`, the pair is the closing delimiter and the mark stands.
        lexer->mark_end(lexer);
        lexer->advance(lexer, false);
        if (lexer->lookahead == '$') {
          if (!advanced) {
            return false;
          }
          lexer->result_symbol = DOLLAR_QUOTE_CONTENT;
          return true;
        }
        advanced = true;
        continue;
      }
      lexer->advance(lexer, false);
      advanced = true;
    }
  }

  return false;
}
