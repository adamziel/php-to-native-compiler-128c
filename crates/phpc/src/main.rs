use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::ExitCode;

use phpc_core::{compile_php, compile_php_executable, run_php, CompileMode};

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
            match parse_compile_args(args.collect::<Vec<_>>().as_slice())? {
                CompileArgs::Text(mode) => {
                    let output = compile_php(&source, mode)?;
                    print!("{output}");
                }
                CompileArgs::Executable { output } => {
                    let runtime_lib = native_runtime_archive()?;
                    compile_php_executable(&source, &output, &runtime_lib)?;
                    println!("{}", output.display());
                }
            }
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

enum CompileArgs {
    Text(CompileMode),
    Executable { output: PathBuf },
}

fn parse_compile_args(args: &[String]) -> Result<CompileArgs, String> {
    if args.is_empty() || args == ["--emit-ir"] {
        return Ok(CompileArgs::Text(CompileMode::EmitIr));
    }
    if args == ["--emit-asm"] {
        return Ok(CompileArgs::Text(CompileMode::EmitAsm));
    }
    if args == ["--emit-exe"] {
        return Err("missing output path for --emit-exe".to_string());
    }
    if args.len() == 2 && args[0] == "--emit-exe" {
        return Ok(CompileArgs::Executable {
            output: PathBuf::from(&args[1]),
        });
    }
    Err(format!("unsupported compile flags: {}", args.join(" ")))
}

fn native_runtime_archive() -> Result<PathBuf, String> {
    if let Ok(path) = env::var("PHPC_RUNTIME_LIB") {
        return Ok(PathBuf::from(path));
    }

    let exe = env::current_exe().map_err(|err| format!("failed to locate current exe: {err}"))?;
    let mut dir = exe
        .parent()
        .ok_or_else(|| format!("failed to locate executable directory for {}", exe.display()))?;
    if dir.file_name().is_some_and(|name| name == "deps") {
        dir = dir
            .parent()
            .ok_or_else(|| format!("failed to locate target directory for {}", exe.display()))?;
    }
    Ok(dir.join("libphp_runtime.a"))
}

fn reject_trailing_args(args: &[String]) -> Result<(), String> {
    if args.is_empty() {
        return Ok(());
    }
    Err(format!("unsupported trailing arguments: {}", args.join(" ")))
}

fn print_help() {
    println!("phpc run <input.php>");
    println!("phpc compile <input.php> [--emit-ir|--emit-asm]");
    println!("phpc compile <input.php> --emit-exe <output>");
}
