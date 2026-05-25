#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Echo(Expression),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expression {
    StringLiteral(String),
    IntegerLiteral(i64),
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
        body = body.trim_start();
        if body.is_empty() || body == "?>" {
            break;
        }
        if let Some(rest) = body.strip_prefix("echo") {
            let (expression, after_expression) = parse_echo_expression(rest.trim_start())?;
            let after_expression = after_expression.trim_start();
            let Some(after_semicolon) = after_expression.strip_prefix(';') else {
                return Err("expected semicolon after echo expression".to_string());
            };
            statements.push(Statement::Echo(expression));
            body = after_semicolon;
            continue;
        }
        return Err(format!(
            "unsupported PHP statement near `{}`",
            body.chars().take(32).collect::<String>()
        ));
    }
    Ok(statements)
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
            value.push(match ch {
                'n' => '\n',
                'r' => '\r',
                't' => '\t',
                '\\' => '\\',
                '"' => '"',
                '\'' => '\'',
                other => other,
            });
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
    fn parses_integer_echo() {
        assert_eq!(
            parse_php("<?php echo 12345;").unwrap(),
            vec![Statement::Echo(Expression::IntegerLiteral(12345))]
        );
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
