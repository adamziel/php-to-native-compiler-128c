mod parser;

pub use parser::{parse_php, Statement};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CompileMode {
    EmitIr,
    EmitAsm,
    EmitExe,
}

pub fn run_php(source: &str) -> Result<String, String> {
    let program = parse_php(source)?;
    let mut output = String::new();
    for statement in program {
        match statement {
            Statement::Echo(text) => output.push_str(&text),
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

fn emit_ir(program: &[Statement]) -> Result<String, String> {
    let mut ir = String::from("; phpc bootstrap LLVM-like IR\n");
    ir.push_str("declare void @phpc_echo(ptr, i64)\n");
    ir.push_str("define i32 @main() {\n");
    for (index, statement) in program.iter().enumerate() {
        match statement {
            Statement::Echo(text) => {
                ir.push_str(&format!(
                    "  ; echo[{index}] len={} text={:?}\n",
                    text.len(),
                    text
                ));
            }
        }
    }
    ir.push_str("  ret i32 0\n}\n");
    Ok(ir)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_echoes_string_literal() {
        assert_eq!(run_php("<?php echo \"hello\";").unwrap(), "hello");
    }

    #[test]
    fn compile_emits_ir_for_echo() {
        let ir = compile_php("<?php echo \"hello\";", CompileMode::EmitIr).unwrap();
        assert!(ir.contains("phpc bootstrap LLVM-like IR"));
        assert!(ir.contains("echo[0]"));
    }
}

