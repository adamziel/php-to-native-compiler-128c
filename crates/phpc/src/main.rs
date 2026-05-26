use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::ExitCode;

use phpc_core::{compile_php, run_php, CompileMode};

fn main() -> ExitCode {
    match real_main() {
        Ok(code) => code,
        Err(err) => {
            eprintln!("{err}");
            ExitCode::from(1)
        }
    }
}

fn real_main() -> Result<ExitCode, String> {
    let mut args = env::args().skip(1);
    let Some(command) = args.next() else {
        print_help();
        return Ok(ExitCode::from(2));
    };

    match command.as_str() {
        "run" => {
            let input = input_path(args.next())?;
            reject_trailing_args(args.collect::<Vec<_>>().as_slice())?;
            let source = fs::read_to_string(&input)
                .map_err(|err| format!("failed to read {}: {err}", input.display()))?;
            let output = run_php(&source)?;
            print!("{output}");
            Ok(ExitCode::SUCCESS)
        }
        "compile" => {
            let input = input_path(args.next())?;
            let source = fs::read_to_string(&input)
                .map_err(|err| format!("failed to read {}: {err}", input.display()))?;
            let mode = parse_compile_mode(args.collect::<Vec<_>>().as_slice())?;
            let output = compile_php(&source, mode)?;
            print!("{output}");
            Ok(ExitCode::SUCCESS)
        }
        "--help" | "-h" | "help" => {
            print_help();
            Ok(ExitCode::SUCCESS)
        }
        other => Err(format!("unknown command `{other}`")),
    }
}

fn input_path(arg: Option<String>) -> Result<PathBuf, String> {
    arg.map(PathBuf::from)
        .ok_or_else(|| "missing input PHP file".to_string())
}

fn parse_compile_mode(args: &[String]) -> Result<CompileMode, String> {
    if args.is_empty() || args == ["--emit-ir"] {
        return Ok(CompileMode::EmitIr);
    }
    if args == ["--emit-asm"] {
        return Ok(CompileMode::EmitAsm);
    }
    if args == ["--emit-exe"] {
        return Ok(CompileMode::EmitExe);
    }
    Err(format!("unsupported compile flags: {}", args.join(" ")))
}

fn reject_trailing_args(args: &[String]) -> Result<(), String> {
    if args.is_empty() {
        return Ok(());
    }
    Err(format!("unsupported trailing arguments: {}", args.join(" ")))
}

fn print_help() {
    println!("phpc run <input.php>");
    println!("phpc compile <input.php> [--emit-ir|--emit-asm|--emit-exe]");
}
