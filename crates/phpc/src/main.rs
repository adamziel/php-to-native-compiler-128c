use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use phpc_core::phpt::{parse_phpt, run_phpt_with_phpc_in_dir, PhptRunReport, PhptRunStatus};
use phpc_core::{compile_php, compile_php_executable, run_php_file, CompileMode};

const WORDPRESS_BOOTSTRAP_ENTRYPOINTS: &[&str] = &[
    "wp-settings.php",
    "wp-blog-header.php",
    "wp-cron.php",
    "wp-admin/admin-ajax.php",
    "xmlrpc.php",
];

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
            let output = run_php_file(&input)?;
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
        "wordpress-bootstrap-check" => {
            let root = input_path(args.next())?;
            reject_trailing_args(args.collect::<Vec<_>>().as_slice())?;
            let report = wordpress_bootstrap_check(&root)?;
            print!("{report}");
            Ok(ExitCode::SUCCESS)
        }
        "phpt-run" => {
            let input = input_path(args.next())?;
            reject_trailing_args(args.collect::<Vec<_>>().as_slice())?;
            let source = fs::read_to_string(&input)
                .map_err(|err| format!("failed to read {}: {err}", input.display()))?;
            let test = parse_phpt(&source)
                .map_err(|err| format!("failed to parse {}: {err}", input.display()))?;
            let base_dir = input.parent().unwrap_or_else(|| Path::new("."));
            let report = run_phpt_with_phpc_in_dir(&test, base_dir);
            print_phpt_run_report(&input, test.test_name(), &report);
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

fn wordpress_bootstrap_check(root: &Path) -> Result<String, String> {
    let mut report = String::new();
    report.push_str("wordpress_bootstrap_check\n");
    report.push_str(&format!("root={}\n", root.display()));

    let mut missing = Vec::new();
    for entrypoint in WORDPRESS_BOOTSTRAP_ENTRYPOINTS {
        let path = root.join(entrypoint);
        if path.is_file() {
            report.push_str(&format!("entrypoint_present={entrypoint}\n"));
        } else {
            report.push_str(&format!("entrypoint_missing={entrypoint}\n"));
            missing.push(*entrypoint);
        }
    }

    if !missing.is_empty() {
        report.push_str("status=blocked\n");
        report.push_str("blocker=missing pinned WordPress entrypoint\n");
        return Ok(report);
    }

    let bootstrap = root.join("wp-settings.php");
    let source = fs::read_to_string(&bootstrap)
        .map_err(|err| format!("failed to read {}: {err}", bootstrap.display()))?;

    match compile_php(&source, CompileMode::EmitIr) {
        Ok(_) => {
            report.push_str("status=unexpected_pass\n");
            report.push_str("blocker=none\n");
        }
        Err(err) => {
            report.push_str("status=blocked\n");
            report.push_str("bootstrap=wp-settings.php\n");
            report.push_str(&format!("general_php_gap={err}\n"));
        }
    }

    Ok(report)
}

fn print_phpt_run_report(input: &Path, test_name: Option<&str>, report: &PhptRunReport) {
    println!("phpt_run");
    println!("path={}", input.display());
    if let Some(test_name) = test_name {
        println!("test_name={}", escape_report_value(test_name));
    }
    println!("runner=phpc_run");
    match &report.status {
        PhptRunStatus::Pass => println!("status=pass"),
        PhptRunStatus::Fail => println!("status=fail"),
        PhptRunStatus::Skip { reason } => {
            println!("status=skip");
            println!("reason={reason}");
        }
        PhptRunStatus::Xfail => println!("status=xfail"),
        PhptRunStatus::UnexpectedPass => println!("status=unexpected_pass"),
        PhptRunStatus::Unsupported { reason } => {
            println!("status=unsupported");
            println!("reason={reason}");
        }
        PhptRunStatus::Error { reason } => {
            println!("status=error");
            println!("reason={reason}");
        }
    }
    if let Some(expected) = report.expected_stdout.as_ref() {
        println!("expected_stdout_len={}", expected.len());
    }
    if let Some(actual) = report.actual_stdout.as_ref() {
        println!("actual_stdout_len={}", actual.len());
    }
    if report.metadata.skip.is_some() {
        println!("has_skipif=true");
    }
    if report.metadata.xfail.is_some() {
        println!("has_xfail=true");
    }
}

fn escape_report_value(value: &str) -> String {
    value.replace('\\', "\\\\").replace('\r', "\\r").replace('\n', "\\n")
}

fn print_help() {
    println!("phpc run <input.php>");
    println!("phpc compile <input.php> [--emit-ir|--emit-asm]");
    println!("phpc compile <input.php> --emit-exe <output>");
    println!("phpc wordpress-bootstrap-check <wordpress-root>");
    println!("phpc phpt-run <input.phpt>");
}
