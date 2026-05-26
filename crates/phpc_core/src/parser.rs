#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Echo(Expression),
    Call(CallExpression),
    Global(Vec<String>),
    Include(IncludeStatement),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CallExpression {
    pub name: String,
    pub arguments: Vec<Expression>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IncludeKind {
    Include,
    Require,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IncludeStatement {
    pub kind: IncludeKind,
    pub path: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expression {
    StringLiteral(String),
    IntegerLiteral(i64),
    BooleanLiteral(bool),
    NullLiteral,
}

pub fn parse_php(source: &str) -> Result<Vec<Statement>, String> {
    let source = source.trim_start();
    let body = source
        .strip_prefix("<?php")
        .ok_or_else(|| "expected PHP source to start with <?php".to_string())?;
    parse_statements(body)
}

fn parse_statements(mut body: &str) -> Result<Vec<Statement>, String> {
    let mut statements = Vec::new();
    loop {
        body = skip_trivia(body)?;
        if body.is_empty()
            || body
                .strip_prefix("?>")
                .is_some_and(|rest| rest.trim().is_empty())
        {
            break;
        }
        if let Some(rest) = body.strip_prefix("echo") {
            let (expression, after_expression) = parse_echo_expression(rest.trim_start())?;
            let after_expression = after_expression.trim_start();
            if let Some(after_semicolon) = after_expression.strip_prefix(';') {
                statements.push(Statement::Echo(expression));
                body = after_semicolon;
                continue;
            }
            if after_expression.trim() == "?>" {
                statements.push(Statement::Echo(expression));
                break;
            };
            return Err("expected semicolon after echo expression".to_string());
        }
        if let Some((call, after_call)) = parse_call_expression(body)? {
            let after_call = after_call.trim_start();
            if let Some(after_semicolon) = after_call.strip_prefix(';') {
                statements.push(Statement::Call(call));
                body = after_semicolon;
                continue;
            }
            return Err("expected semicolon after function call statement".to_string());
        }
        if let Some((names, after_global)) = parse_global_statement(body)? {
            let after_global = after_global.trim_start();
            if let Some(after_semicolon) = after_global.strip_prefix(';') {
                statements.push(Statement::Global(names));
                body = after_semicolon;
                continue;
            }
            return Err("expected semicolon after global declaration".to_string());
        }
        if let Some((include, after_include)) = parse_include_or_require_statement(body)? {
            let after_include = after_include.trim_start();
            if let Some(after_semicolon) = after_include.strip_prefix(';') {
                statements.push(Statement::Include(include));
                body = after_semicolon;
                continue;
            }
            return Err("expected semicolon after include/require statement".to_string());
        }
        return Err(format!(
            "unsupported PHP statement near `{}`",
            body.chars().take(32).collect::<String>()
        ));
    }
    Ok(statements)
}

fn skip_trivia(mut input: &str) -> Result<&str, String> {
    loop {
        input = input.trim_start();
        if let Some(rest) = input.strip_prefix("/*") {
            let Some(end) = rest.find("*/") else {
                return Err("unterminated block comment".to_string());
            };
            input = &rest[end + 2..];
            continue;
        }
        if let Some(rest) = input.strip_prefix("//") {
            input = skip_line_comment(rest);
            continue;
        }
        if let Some(rest) = input.strip_prefix('#') {
            input = skip_line_comment(rest);
            continue;
        }
        return Ok(input);
    }
}

fn skip_line_comment(input: &str) -> &str {
    match input.find('\n') {
        Some(index) => &input[index + 1..],
        None => "",
    }
}

fn parse_echo_expression(input: &str) -> Result<(Expression, &str), String> {
    if input.starts_with('$') {
        return Err(
            "unsupported echo expression: variables require native symbol table lowering".to_string(),
        );
    }
    if input.starts_with('"') || input.starts_with('\'') {
        let (value, rest) = parse_string_literal(input)?;
        return Ok((Expression::StringLiteral(value), rest));
    }
    if input
        .chars()
        .next()
        .is_some_and(|ch| ch.is_ascii_digit())
    {
        let (value, rest) = parse_integer_literal(input)?;
        return Ok((Expression::IntegerLiteral(value), rest));
    }
    if let Some((value, rest)) = parse_boolean_literal(input) {
        return Ok((Expression::BooleanLiteral(value), rest));
    }
    if let Some(rest) = parse_null_literal(input) {
        return Ok((Expression::NullLiteral, rest));
    }
    Err("expected echo expression literal".to_string())
}

fn parse_call_expression(input: &str) -> Result<Option<(CallExpression, &str)>, String> {
    let Some((name, rest)) = parse_identifier(input) else {
        return Ok(None);
    };
    if !name.eq_ignore_ascii_case("define") {
        return Ok(None);
    }
    let Some(mut rest) = rest.strip_prefix('(') else {
        return Ok(None);
    };
    let mut arguments = Vec::new();
    loop {
        rest = rest.trim_start();
        if let Some(after_close) = rest.strip_prefix(')') {
            return Ok(Some((
                CallExpression {
                    name: name.to_string(),
                    arguments,
                },
                after_close,
            )));
        }

        let (argument, after_argument) = parse_echo_expression(rest)?;
        arguments.push(argument);
        rest = after_argument.trim_start();

        if let Some(after_comma) = rest.strip_prefix(',') {
            rest = after_comma;
            continue;
        }
        if let Some(after_close) = rest.strip_prefix(')') {
            return Ok(Some((
                CallExpression {
                    name: name.to_string(),
                    arguments,
                },
                after_close,
            )));
        }
        return Err("expected comma or closing parenthesis after function call argument".to_string());
    }
}

fn parse_global_statement(input: &str) -> Result<Option<(Vec<String>, &str)>, String> {
    let Some(mut rest) = parse_keyword(input, "global") else {
        return Ok(None);
    };
    rest = rest.trim_start();

    let mut names = Vec::new();
    loop {
        let Some((name, after_variable)) = parse_variable_name(rest) else {
            return Err("expected variable name in global declaration".to_string());
        };
        names.push(name.to_string());
        rest = after_variable.trim_start();

        if let Some(after_comma) = rest.strip_prefix(',') {
            rest = after_comma.trim_start();
            continue;
        }
        return Ok(Some((names, rest)));
    }
}

fn parse_variable_name(input: &str) -> Option<(&str, &str)> {
    let rest = input.strip_prefix('$')?;
    let (name, after_name) = parse_identifier(rest)?;
    Some((name, after_name))
}

fn parse_include_or_require_statement(
    input: &str,
) -> Result<Option<(IncludeStatement, &str)>, String> {
    for (keyword, kind) in [
        ("require_once", None),
        ("include_once", None),
        ("require", Some(IncludeKind::Require)),
        ("include", Some(IncludeKind::Include)),
    ] {
        let Some(rest) = parse_keyword(input, keyword) else {
            continue;
        };
        let Some(kind) = kind else {
            return Err(format!(
                "unsupported {keyword} statement: include_once/require_once execution is not implemented"
            ));
        };
        let rest = rest.trim_start();
        if !(rest.starts_with('"') || rest.starts_with('\'')) {
            return Err(format!(
                "unsupported {keyword} statement: expected literal string path"
            ));
        }
        let (path, rest) = parse_string_literal(rest)?;
        return Ok(Some((IncludeStatement { kind, path }, rest)));
    }
    Ok(None)
}

fn parse_identifier(input: &str) -> Option<(&str, &str)> {
    let mut chars = input.char_indices();
    let (_, first) = chars.next()?;
    if !(first == '_' || first.is_ascii_alphabetic()) {
        return None;
    }
    let end = chars
        .find_map(|(index, ch)| {
            (!(ch == '_' || ch.is_ascii_alphanumeric())).then_some(index)
        })
        .unwrap_or(input.len());
    Some((&input[..end], &input[end..]))
}

fn parse_string_literal(input: &str) -> Result<(String, &str), String> {
    let mut chars = input.char_indices();
    let Some((_, quote @ ('"' | '\''))) = chars.next() else {
        return Err("expected string literal".to_string());
    };
    let mut value = String::new();
    let mut escaped = false;
    for (index, ch) in chars {
        if escaped {
            if quote == '\'' {
                match ch {
                    '\\' | '\'' => value.push(ch),
                    other => {
                        value.push('\\');
                        value.push(other);
                    }
                }
            } else {
                value.push(match ch {
                    'n' => '\n',
                    'r' => '\r',
                    't' => '\t',
                    '\\' => '\\',
                    '"' => '"',
                    '\'' => '\'',
                    other => other,
                });
            }
            escaped = false;
            continue;
        }
        if ch == '\\' {
            escaped = true;
            continue;
        }
        if ch == quote {
            return Ok((value, &input[index + ch.len_utf8()..]));
        }
        value.push(ch);
    }
    Err("unterminated string literal".to_string())
}

fn parse_integer_literal(input: &str) -> Result<(i64, &str), String> {
    let end = input
        .char_indices()
        .find_map(|(index, ch)| (!ch.is_ascii_digit()).then_some(index))
        .unwrap_or(input.len());
    let literal = &input[..end];
    let value = literal
        .parse::<i64>()
        .map_err(|_| format!("integer literal out of range: {literal}"))?;
    Ok((value, &input[end..]))
}

fn parse_boolean_literal(input: &str) -> Option<(bool, &str)> {
    if let Some(rest) = parse_keyword(input, "true") {
        return Some((true, rest));
    }
    if let Some(rest) = parse_keyword(input, "false") {
        return Some((false, rest));
    }
    None
}

fn parse_null_literal(input: &str) -> Option<&str> {
    parse_keyword(input, "null")
}

fn parse_keyword<'a>(input: &'a str, keyword: &str) -> Option<&'a str> {
    let candidate = input.get(..keyword.len())?;
    if !candidate.eq_ignore_ascii_case(keyword) {
        return None;
    }
    let rest = &input[keyword.len()..];
    if rest
        .chars()
        .next()
        .is_some_and(|ch| ch.is_ascii_alphanumeric() || ch == '_')
    {
        return None;
    }
    Some(rest)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_echo() {
        assert_eq!(
            parse_php("<?php echo 'hello';").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "hello".to_string()
            ))]
        );
    }

    #[test]
    fn parses_single_quoted_string_escapes_like_php() {
        assert_eq!(
            parse_php("<?php echo 'a\\nb \\\\ \\' c';").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "a\\nb \\ ' c".to_string()
            ))]
        );
    }

    #[test]
    fn parses_double_quoted_string_newline_escape() {
        assert_eq!(
            parse_php("<?php echo \"a\\nb\";").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "a\nb".to_string()
            ))]
        );
    }

    #[test]
    fn parses_integer_echo() {
        assert_eq!(
            parse_php("<?php echo 12345;").unwrap(),
            vec![Statement::Echo(Expression::IntegerLiteral(12345))]
        );
    }

    #[test]
    fn parses_echo_boolean_literals_case_insensitively() {
        assert_eq!(
            parse_php("<?php echo true; echo FALSE;").unwrap(),
            vec![
                Statement::Echo(Expression::BooleanLiteral(true)),
                Statement::Echo(Expression::BooleanLiteral(false))
            ]
        );
    }

    #[test]
    fn parses_echo_null_literal_case_insensitively() {
        assert_eq!(
            parse_php("<?php echo NuLl;").unwrap(),
            vec![Statement::Echo(Expression::NullLiteral)]
        );
    }

    #[test]
    fn does_not_parse_literal_keyword_prefixes() {
        let err = parse_php("<?php echo trueish;").unwrap_err();
        assert_eq!(err, "expected echo expression literal");
    }

    #[test]
    fn parses_final_echo_before_closing_tag_without_semicolon() {
        assert_eq!(
            parse_php("<?php echo \"hello\" ?>").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "hello".to_string()
            ))]
        );
    }

    #[test]
    fn parses_echo_after_leading_block_comment() {
        assert_eq!(
            parse_php("<?php\n/** bootstrap docs */\necho 'hello';").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "hello".to_string()
            ))]
        );
    }

    #[test]
    fn parses_echo_after_line_comments() {
        assert_eq!(
            parse_php("<?php\n// line comment\n# shell-style comment\necho 123;").unwrap(),
            vec![Statement::Echo(Expression::IntegerLiteral(123))]
        );
    }

    #[test]
    fn parses_top_level_define_call_with_string_literals() {
        assert_eq!(
            parse_php("<?php define( 'WPINC', 'wp-includes' );").unwrap(),
            vec![Statement::Call(CallExpression {
                name: "define".to_string(),
                arguments: vec![
                    Expression::StringLiteral("WPINC".to_string()),
                    Expression::StringLiteral("wp-includes".to_string()),
                ],
            })]
        );
    }

    #[test]
    fn parses_define_after_leading_block_comment() {
        assert_eq!(
            parse_php("<?php\n/** bootstrap docs */\ndefine( 'WPINC', 'wp-includes' );").unwrap(),
            vec![Statement::Call(CallExpression {
                name: "define".to_string(),
                arguments: vec![
                    Expression::StringLiteral("WPINC".to_string()),
                    Expression::StringLiteral("wp-includes".to_string()),
                ],
            })]
        );
    }

    #[test]
    fn parses_top_level_global_declaration() {
        assert_eq!(
            parse_php("<?php global $wp_version, $wp_db_version;").unwrap(),
            vec![Statement::Global(vec![
                "wp_version".to_string(),
                "wp_db_version".to_string(),
            ])]
        );
    }

    #[test]
    fn parses_global_after_define_and_comments() {
        assert_eq!(
            parse_php(
                "<?php\n/** bootstrap docs */\ndefine( 'WPINC', 'wp-includes' );\nglobal $first, $second;"
            )
            .unwrap(),
            vec![
                Statement::Call(CallExpression {
                    name: "define".to_string(),
                    arguments: vec![
                        Expression::StringLiteral("WPINC".to_string()),
                        Expression::StringLiteral("wp-includes".to_string()),
                    ],
                }),
                Statement::Global(vec!["first".to_string(), "second".to_string()]),
            ]
        );
    }

    #[test]
    fn parses_closing_tag_with_trailing_whitespace_after_statement() {
        assert_eq!(
            parse_php("<?php\necho \"hello\\n\";\n?>\n").unwrap(),
            vec![Statement::Echo(Expression::StringLiteral(
                "hello\n".to_string()
            ))]
        );
    }

    #[test]
    fn parses_literal_require_statement() {
        assert_eq!(
            parse_php("<?php require 'lib.php'; echo 'done';").unwrap(),
            vec![
                Statement::Include(IncludeStatement {
                    kind: IncludeKind::Require,
                    path: "lib.php".to_string(),
                }),
                Statement::Echo(Expression::StringLiteral("done".to_string())),
            ]
        );
    }

    #[test]
    fn parses_literal_include_statement() {
        assert_eq!(
            parse_php("<?php include \"partials/header.php\";").unwrap(),
            vec![Statement::Include(IncludeStatement {
                kind: IncludeKind::Include,
                path: "partials/header.php".to_string(),
            })]
        );
    }

    #[test]
    fn rejects_global_without_variable_name() {
        let err = parse_php("<?php global ;").unwrap_err();
        assert_eq!(err, "expected variable name in global declaration");
    }

    #[test]
    fn rejects_global_without_semicolon() {
        let err = parse_php("<?php global $name echo 'x';").unwrap_err();
        assert_eq!(err, "expected semicolon after global declaration");
    }

    #[test]
    fn rejects_function_call_without_semicolon() {
        let err = parse_php("<?php define('WPINC', 'wp-includes') echo 'x';").unwrap_err();
        assert_eq!(err, "expected semicolon after function call statement");
    }

    #[test]
    fn rejects_require_with_precise_unsupported_diagnostic() {
        let err = parse_php("<?php require APP_DIR . '/bootstrap.php';").unwrap_err();
        assert_eq!(
            err,
            "unsupported require statement: expected literal string path"
        );
    }

    #[test]
    fn rejects_include_once_with_precise_unsupported_diagnostic() {
        let err = parse_php("<?php include_once 'bootstrap.php';").unwrap_err();
        assert_eq!(
            err,
            "unsupported include_once statement: include_once/require_once execution is not implemented"
        );
    }

    #[test]
    fn rejects_require_once_with_precise_unsupported_diagnostic() {
        for source in [
            "<?php require_once 'bootstrap.php';",
            "<?php require_once APP_DIR . '/bootstrap.php';",
        ] {
            let err = parse_php(source).unwrap_err();
            assert_eq!(
                err,
                "unsupported require_once statement: include_once/require_once execution is not implemented",
                "{source}"
            );
        }
    }

    #[test]
    fn does_not_classify_include_keyword_prefixes_as_include_statements() {
        let err = parse_php("<?php include_path();").unwrap_err();
        assert_eq!(err, "unsupported PHP statement near `include_path();`");
    }

    #[test]
    fn rejects_unterminated_block_comment() {
        let err = parse_php("<?php /* missing end echo 'hello';").unwrap_err();
        assert_eq!(err, "unterminated block comment");
    }

    #[test]
    fn rejects_variable_echo_with_explicit_diagnostic() {
        let err = parse_php("<?php echo $name;").unwrap_err();
        assert!(err.contains("variables require native symbol table lowering"));
    }

    #[test]
    fn rejects_non_php_source() {
        assert!(parse_php("echo 'hello';").is_err());
    }
}
