mod parser;
pub mod phpt;

use std::collections::HashMap;
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

pub use parser::{parse_php, CallExpression, Expression, Statement};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CompileMode {
    EmitIr,
    EmitAsm,
    EmitExe,
}

pub fn run_php(source: &str) -> Result<String, String> {
    let program = parse_php(source)?;
    let mut constants = HashMap::new();
    let mut output = String::new();
    for statement in program {
        match statement {
            Statement::Echo(expression) => match expression {
                Expression::StringLiteral(text) => output.push_str(&text),
                Expression::IntegerLiteral(value) => output.push_str(&value.to_string()),
                Expression::BooleanLiteral(true) => output.push('1'),
                Expression::BooleanLiteral(false) | Expression::NullLiteral => {}
            },
            Statement::Call(call) => interpret_call_statement(call, &mut constants)?,
        }
    }
    Ok(output)
}

pub fn compile_php(source: &str, mode: CompileMode) -> Result<String, String> {
    let program = parse_php(source)?;
    match mode {
        CompileMode::EmitIr => emit_ir(&program),
        CompileMode::EmitAsm => Err("native assembly emission is not implemented yet".to_string()),
        CompileMode::EmitExe => Err("linked native executable emission is not implemented yet".to_string()),
    }
}

pub fn compile_php_executable(
    source: &str,
    output_path: &Path,
    runtime_lib: &Path,
) -> Result<(), String> {
    if !runtime_lib.is_file() {
        return Err(format!(
            "native runtime archive not found: {}",
            runtime_lib.display()
        ));
    }

    let program = parse_php(source)?;
    let ir = emit_linkable_ir(&program)?;
    let ir_path = temporary_ir_path(output_path)?;
    fs::write(&ir_path, ir)
        .map_err(|err| format!("failed to write temporary IR {}: {err}", ir_path.display()))?;

    let status = Command::new("clang")
        .arg(&ir_path)
        .arg(runtime_lib)
        .arg("-o")
        .arg(output_path)
        .status()
        .map_err(|err| format!("failed to invoke clang for native link: {err}"))?;

    let _ = fs::remove_file(&ir_path);

    if status.success() {
        Ok(())
    } else {
        Err(format!("native link failed with status {status}"))
    }
}

fn emit_ir(program: &[Statement]) -> Result<String, String> {
    let mut ir = String::from("; phpc bootstrap LLVM-like IR\n");
    ir.push_str("declare void @phpc_echo(ptr, i64)\n");
    ir.push_str("define i32 @main() {\n");
    for (index, statement) in program.iter().enumerate() {
        match statement {
            Statement::Call(call) => {
                let (name, value) = define_string_literal(call)?;
                ir.push_str(&format!(
                    "  ; define_string[{index}] name={name:?} value={value:?}\n"
                ));
            }
            Statement::Echo(Expression::StringLiteral(text)) => {
                ir.push_str(&format!(
                    "  ; echo_string[{index}] len={} text={:?}\n",
                    text.len(),
                    text
                ));
            }
            Statement::Echo(Expression::IntegerLiteral(value)) => {
                ir.push_str(&format!("  ; echo_int[{index}] value={value}\n"));
            }
            Statement::Echo(Expression::BooleanLiteral(value)) => {
                ir.push_str(&format!("  ; echo_bool[{index}] value={value}\n"));
            }
            Statement::Echo(Expression::NullLiteral) => {
                ir.push_str(&format!("  ; echo_null[{index}]\n"));
            }
        }
    }
    ir.push_str("  ret i32 0\n}\n");
    Ok(ir)
}

fn emit_linkable_ir(program: &[Statement]) -> Result<String, String> {
    let mut globals = String::new();
    let mut body = String::new();

    for (index, statement) in program.iter().enumerate() {
        let bytes = match statement {
            Statement::Call(call) => {
                define_string_literal(call)?;
                continue;
            }
            Statement::Echo(Expression::StringLiteral(text)) => text.as_bytes().to_vec(),
            Statement::Echo(Expression::IntegerLiteral(value)) => value.to_string().into_bytes(),
            Statement::Echo(Expression::BooleanLiteral(true)) => b"1".to_vec(),
            Statement::Echo(Expression::BooleanLiteral(false) | Expression::NullLiteral) => {
                Vec::new()
            }
        };
        globals.push_str(&format!(
            "@.phpc.echo.{index} = private unnamed_addr constant [{} x i8] c\"{}\"\n",
            bytes.len(),
            llvm_c_string(&bytes)
        ));
        body.push_str(&format!(
            "  call void @phpc_echo(ptr @.phpc.echo.{index}, i64 {})\n",
            bytes.len()
        ));
    }

    Ok(format!(
        "; phpc linked native bootstrap IR\n\
         {globals}\
         declare void @phpc_echo(ptr, i64)\n\
         define i32 @main() {{\n\
         {body}\
           ret i32 0\n\
         }}\n"
    ))
}

fn interpret_call_statement(
    call: CallExpression,
    constants: &mut HashMap<String, String>,
) -> Result<(), String> {
    if call.name.eq_ignore_ascii_case("define") {
        let (name, value) = define_string_literal(&call)?;
        constants.insert(name.to_string(), value.to_string());
        return Ok(());
    }
    Err(format!(
        "unsupported function call statement: {}",
        call.name
    ))
}

fn define_string_literal(call: &CallExpression) -> Result<(&str, &str), String> {
    if !call.name.eq_ignore_ascii_case("define") {
        return Err(format!(
            "unsupported function call statement: {}",
            call.name
        ));
    }
    match call.arguments.as_slice() {
        [Expression::StringLiteral(name), Expression::StringLiteral(value)] => {
            Ok((name.as_str(), value.as_str()))
        }
        _ => Err(
            "unsupported define() statement: expected string literal name and value".to_string(),
        ),
    }
}

fn llvm_c_string(bytes: &[u8]) -> String {
    let mut escaped = String::new();
    for &byte in bytes {
        match byte {
            b'\\' => escaped.push_str("\\5C"),
            b'"' => escaped.push_str("\\22"),
            0x20..=0x7e => escaped.push(byte as char),
            _ => escaped.push_str(&format!("\\{byte:02X}")),
        }
    }
    escaped
}

fn temporary_ir_path(output_path: &Path) -> Result<PathBuf, String> {
    let stem = output_path
        .file_name()
        .and_then(OsStr::to_str)
        .unwrap_or("phpc-native");
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|err| format!("system clock is before UNIX_EPOCH: {err}"))?
        .as_nanos();
    Ok(std::env::temp_dir().join(format!(
        "{stem}.{}.{}.ll",
        std::process::id(),
        nanos
    )))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_echoes_string_literal() {
        assert_eq!(run_php("<?php echo \"hello\";").unwrap(), "hello");
    }

    #[test]
    fn run_preserves_single_quoted_backslash_n() {
        assert_eq!(run_php("<?php echo 'a\\nb';").unwrap(), "a\\nb");
    }

    #[test]
    fn compile_emits_ir_for_echo() {
        let ir = compile_php("<?php echo \"hello\";", CompileMode::EmitIr).unwrap();
        assert!(ir.contains("phpc bootstrap LLVM-like IR"));
        assert!(ir.contains("echo_string[0]"));
    }

    #[test]
    fn run_echoes_integer_literal() {
        assert_eq!(run_php("<?php echo 12345;").unwrap(), "12345");
    }

    #[test]
    fn run_echoes_final_literal_before_closing_tag_without_semicolon() {
        assert_eq!(run_php("<?php echo \"hello\" ?>").unwrap(), "hello");
    }

    #[test]
    fn compile_emits_ir_for_integer_echo() {
        let ir = compile_php("<?php echo 12345;", CompileMode::EmitIr).unwrap();
        assert!(ir.contains("echo_int[0] value=12345"));
    }

    #[test]
    fn run_echoes_boolean_and_null_literals_like_php() {
        assert_eq!(
            run_php("<?php echo true; echo false; echo null;").unwrap(),
            "1"
        );
    }

    #[test]
    fn compile_emits_ir_for_boolean_and_null_literals() {
        let ir = compile_php(
            "<?php echo true; echo false; echo null;",
            CompileMode::EmitIr,
        )
        .unwrap();

        assert!(ir.contains("echo_bool[0] value=true"));
        assert!(ir.contains("echo_bool[1] value=false"));
        assert!(ir.contains("echo_null[2]"));
    }

    #[test]
    fn run_interprets_define_string_literal_statement_without_output() {
        assert_eq!(
            run_php("<?php define( 'WPINC', 'wp-includes' ); echo 'ok';").unwrap(),
            "ok"
        );
    }

    #[test]
    fn compile_emits_ir_for_define_string_literal_statement() {
        let ir = compile_php(
            "<?php define( 'WPINC', 'wp-includes' ); echo 'ok';",
            CompileMode::EmitIr,
        )
        .unwrap();

        assert!(ir.contains("define_string[0] name=\"WPINC\" value=\"wp-includes\""));
        assert!(ir.contains("echo_string[1] len=2 text=\"ok\""));
    }

    #[test]
    fn rejects_define_with_non_string_value() {
        let err = run_php("<?php define( 'WP_DEBUG', true );").unwrap_err();
        assert_eq!(
            err,
            "unsupported define() statement: expected string literal name and value"
        );
    }

    #[test]
    fn linkable_ir_calls_runtime_echo_for_supported_literals() {
        let program =
            parse_php("<?php echo \"hi\\n\"; echo 42; echo true; echo false; echo null;").unwrap();
        let ir = emit_linkable_ir(&program).unwrap();

        assert!(ir.contains("declare void @phpc_echo(ptr, i64)"));
        assert!(ir.contains("c\"hi\\0A\""));
        assert!(ir.contains("c\"42\""));
        assert!(ir.contains("c\"1\""));
        assert!(ir.contains("[0 x i8] c\"\""));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.0, i64 3)"));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.1, i64 2)"));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.2, i64 1)"));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.3, i64 0)"));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.4, i64 0)"));
    }

    #[test]
    fn linkable_ir_calls_runtime_echo_without_semicolon_before_closing_tag() {
        let program = parse_php("<?php echo \"native\" ?>").unwrap();
        let ir = emit_linkable_ir(&program).unwrap();

        assert!(ir.contains("c\"native\""));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.0, i64 6)"));
    }

    #[test]
    fn linkable_ir_accepts_define_string_literal_statement_as_no_output() {
        let program = parse_php("<?php define('WPINC', 'wp-includes'); echo \"native\";").unwrap();
        let ir = emit_linkable_ir(&program).unwrap();

        assert!(!ir.contains("wp-includes"));
        assert!(ir.contains("c\"native\""));
        assert!(ir.contains("call void @phpc_echo(ptr @.phpc.echo.1, i64 6)"));
    }
}
