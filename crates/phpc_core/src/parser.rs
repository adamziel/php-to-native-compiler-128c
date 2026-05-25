#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Echo(String),
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
            let (text, after_literal) = parse_string_literal(rest.trim_start())?;
            let after_literal = after_literal.trim_start();
            let Some(after_semicolon) = after_literal.strip_prefix(';') else {
                return Err("expected semicolon after echo string literal".to_string());
            };
            statements.push(Statement::Echo(text));
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_echo() {
        assert_eq!(
            parse_php("<?php echo 'hello';").unwrap(),
            vec![Statement::Echo("hello".to_string())]
        );
    }

    #[test]
    fn rejects_non_php_source() {
        assert!(parse_php("echo 'hello';").is_err());
    }
}

