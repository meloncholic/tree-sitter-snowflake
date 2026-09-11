use crate::{Body, BodySource, BodyStatus, ExecutionRights, Language, RoutineKind, descendants};
use tree_sitter::Tree;

pub(crate) fn bodies(sql: &str, tree: &Tree) -> Vec<Body> {
    let mut result = Vec::new();
    for routine in descendants(tree.root_node()) {
        let kind = match routine.kind() {
            "create_procedure" | "alter_procedure" => RoutineKind::Procedure,
            "create_function" | "alter_function" => RoutineKind::Function,
            _ => continue,
        };
        let Some(language_node) = routine.child_by_field_name("language") else {
            continue;
        };
        let language = descendants(language_node)
            .into_iter()
            .find_map(|node| match node.kind() {
                "keyword_javascript" => Some(Language::JavaScript),
                "keyword_python" => Some(Language::Python),
                "keyword_java" => Some(Language::Java),
                "keyword_scala" => Some(Language::Scala),
                _ => None,
            });
        let Some(language) = language else { continue };
        let Some(wrapper) = routine.child_by_field_name("body") else {
            continue;
        };
        let form = descendants(wrapper)
            .into_iter()
            .find(|n| matches!(n.kind(), "string_body" | "dollar_quoted_body"));
        let mut rights = if kind == RoutineKind::Procedure {
            ExecutionRights::Owner
        } else {
            ExecutionRights::NotApplicable
        };
        if kind == RoutineKind::Procedure {
            for node in descendants(routine)
                .into_iter()
                .filter(|n| n.kind() == "execute_as_clause" && n.end_byte() <= wrapper.start_byte())
            {
                rights = if descendants(node)
                    .iter()
                    .any(|n| n.kind() == "keyword_caller")
                {
                    ExecutionRights::Caller
                } else if descendants(node)
                    .iter()
                    .any(|n| n.kind() == "keyword_owner")
                {
                    ExecutionRights::Owner
                } else {
                    ExecutionRights::Unknown
                };
            }
        }
        let mut body = Body {
            name: routine
                .child_by_field_name("name")
                .map(|n| sql[n.byte_range()].to_owned())
                .unwrap_or_default(),
            routine_kind: kind,
            language,
            rights,
            routine_range: routine.byte_range(),
            body_range: wrapper.byte_range(),
            source: None,
            tree: None,
            status: BodyStatus::InvalidSql,
            parse_errors: Vec::new(),
            findings: Vec::new(),
        };
        if !routine.has_error()
            && let Some(form) = form
        {
            let delimiters = if form.kind() == "string_body" { 1 } else { 2 };
            let range = form.start_byte() + delimiters..form.end_byte() - delimiters;
            let decoded = if delimiters == 1 {
                BodySource::quoted(&sql[range.clone()], range.start)
            } else {
                Ok(BodySource::verbatim(&sql[range.clone()], range.start))
            };
            match decoded {
                Ok(source) => {
                    body.source = Some(source);
                    body.status = BodyStatus::UnavailableLanguage;
                }
                Err(message) => body.status = BodyStatus::InvalidEncoding(message),
            }
        }
        result.push(body);
    }
    result
}
