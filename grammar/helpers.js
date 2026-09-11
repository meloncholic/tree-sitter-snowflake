export function make_keyword(word) {
  let str = "";
  for (var i = 0; i < word.length; i++) {
    str = str + "[" + word.charAt(i).toLowerCase() + word.charAt(i).toUpperCase() + "]";
  }
  return new RegExp(str);
}

export function optional_parenthesis(node) {
  return prec.right(
    choice(
      node,
      wrapped_in_parenthesis(node),
    ),
  )
}

export function wrapped_in_parenthesis(node) {
  if (node) {
    return seq("(", node, ")");
  }
  return seq("(", ")");
}

export function comma_list(field, requireFirst) {
  let sequence = seq(field, repeat(seq(',', field)));

  if (requireFirst) {
    return sequence;
  }

  return optional(sequence);
}

export function paren_list(field, requireFirst) {
  return wrapped_in_parenthesis(
    comma_list(field, requireFirst),
  )
}

// `;`-separated statements with the final terminator optional — the body
// shape `program` and every scripting block share. A plain function, not
// a named rule: the empty-body case would make a named rule match the
// empty string, which tree-sitter rejects outside the start rule.
// Snowflake requires the separator between scripting statements, and
// keeping it mandatory is what keeps statement-initial keywords (BREAK,
// LET, RETURN, ...) out of the AS-less alias slot — with the separator
// optional inside a body, the state after any completed statement also
// accepts a fresh statement, and LALR merges that with the alias slot's
// state.
// `;`-terminated statements — the body shape every scripting block and
// the `$$` script share. Snowflake requires the terminator after each
// scripting statement. A plain function, not a named rule: the empty-body
// case would make a named rule match the empty string, which tree-sitter
// rejects outside the start rule. Keeping the terminator mandatory is
// also what keeps statement-initial keywords (BREAK, LET, RETURN, ...)
// out of the AS-less alias slot — with the terminator optional inside a
// body, the state after any completed statement also accepts a fresh
// statement, and LALR merges that with the alias slot's state. DECLARE
// self-terminates (each declaration carries its own `;`) so it takes no
// separator after it.
export function statement_list($) {
  return repeat(choice(
    $.declare_statement,
    seq($.statement, ';'),
  ))
}
