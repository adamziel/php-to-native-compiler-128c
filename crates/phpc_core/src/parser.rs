#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Echo(Expression),
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
        if body.is_empty() || body == "?>" {
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
