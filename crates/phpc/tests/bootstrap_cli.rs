use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use std::{env, fs};

const BOOTSTRAP_HELLO: &str = "../../fixtures/bootstrap/hello.php";
const BOOTSTRAP_BOOL_NULL: &str = "../../fixtures/bootstrap/bool_null_echo.php";
const BOOTSTRAP_REQUIRE_SIBLING: &str = "../../fixtures/bootstrap/require_sibling_main.php";

#[test]
fn cli_without_command_prints_help_and_usage_exit() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe).output().expect("run phpc");

    assert_eq!(output.status.code(), Some(2));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("phpc run <input.php>"));
    assert!(stdout.contains("phpc compile <input.php> --emit-exe <output>"));
    assert!(stdout.contains("phpc wordpress-bootstrap-check <wordpress-root>"));
    assert!(stdout.contains("phpc phpt-run <input.phpt>"));
    assert_eq!(String::from_utf8_lossy(&output.stderr), "");
}

#[test]
fn cli_help_aliases_print_usage_successfully() {
    let exe = env!("CARGO_BIN_EXE_phpc");

    for arg in ["--help", "-h", "help"] {
        let output = Command::new(exe).arg(arg).output().expect("run phpc help");

        assert!(
            output.status.success(),
            "{arg} failed with stderr:\n{}",
            String::from_utf8_lossy(&output.stderr)
        );
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(stdout.contains("phpc run <input.php>"), "{arg} stdout:\n{stdout}");
        assert!(
            stdout.contains("phpc compile <input.php> --emit-exe <output>"),
            "{arg} stdout:\n{stdout}"
        );
        assert!(
            stdout.contains("phpc wordpress-bootstrap-check <wordpress-root>"),
            "{arg} stdout:\n{stdout}"
        );
        assert!(
            stdout.contains("phpc phpt-run <input.phpt>"),
            "{arg} stdout:\n{stdout}"
        );
        assert_eq!(String::from_utf8_lossy(&output.stderr), "", "{arg}");
    }
}

#[test]
fn cli_rejects_unknown_command_without_stdout() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .arg("definitely-not-a-command")
        .output()
        .expect("run phpc unknown command");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unknown command `definitely-not-a-command`"));
}

#[test]
fn cli_runs_bootstrap_echo() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["run", BOOTSTRAP_HELLO])
        .output()
        .expect("run phpc");
    assert!(output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "hello from phpc\n");
}

#[test]
fn cli_run_executes_literal_require_sibling_file() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["run", BOOTSTRAP_REQUIRE_SIBLING])
        .output()
        .expect("run phpc");

    assert!(
        output.status.success(),
        "phpc run failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        String::from_utf8_lossy(&output.stdout),
        "main-before|sibling|main-after"
    );
    assert_eq!(String::from_utf8_lossy(&output.stderr), "");
}

#[test]
fn cli_runs_minimal_phpt_with_phpc_runner() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-phpt-run");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let phpt = dir.join("basic_001.phpt");
    std::fs::write(
        &phpt,
        "--TEST--\nTrivial \"Hello World\" test\n--FILE--\n<?php echo \"Hello World\"?>\n--EXPECT--\nHello World\n",
    )
    .expect("write phpt");

    let output = Command::new(exe)
        .args(["phpt-run"])
        .arg(&phpt)
        .output()
        .expect("run phpc phpt-run");

    assert!(
        output.status.success(),
        "phpt-run failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("phpt_run\n"));
    assert!(stdout.contains("runner=phpc_run\n"));
    assert!(stdout.contains("status=pass\n"));
    assert!(stdout.contains("expected_stdout_len=11\n"));
    assert!(stdout.contains("actual_stdout_len=11\n"));
    assert_eq!(String::from_utf8_lossy(&output.stderr), "");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_run_rejects_trailing_arguments() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["run", "../../fixtures/bootstrap/hello.php", "--emit-ir"])
        .output()
        .expect("run phpc");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported trailing arguments: --emit-ir"));
}

#[test]
fn cli_run_requires_input_file() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe).arg("run").output().expect("run phpc");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr).contains("missing input PHP file"));
}

#[test]
fn cli_compile_rejects_conflicting_emit_flags() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["compile", "../../fixtures/bootstrap/hello.php", "--emit-ir", "--emit-exe"])
        .output()
        .expect("run phpc");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported compile flags: --emit-ir --emit-exe"));
}

#[test]
fn cli_compile_requires_input_file() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe).arg("compile").output().expect("run phpc");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr).contains("missing input PHP file"));
}

#[test]
fn cli_compile_emit_exe_requires_output_path() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["compile", BOOTSTRAP_HELLO, "--emit-exe"])
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("missing output path for --emit-exe"));
    assert!(output.stdout.is_empty());
}

#[test]
fn cli_compile_emit_exe_rejects_extra_arguments_after_output_path() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args([
            "compile",
            BOOTSTRAP_HELLO,
            "--emit-exe",
            "/tmp/phpc-native-output",
            "--emit-ir",
        ])
        .output()
        .expect("run phpc compile --emit-exe with extra argument");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported compile flags: --emit-exe /tmp/phpc-native-output --emit-ir"));
    assert!(output.stdout.is_empty());
}

#[test]
fn cli_compile_emit_exe_removes_stale_output_when_runtime_archive_is_missing() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-stale-native-output");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let output_path = dir.join("stale-native");
    std::fs::write(&output_path, "old executable contents").expect("write stale output");

    let output = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", dir.join("missing-libphp_runtime.a"))
        .args(["compile", BOOTSTRAP_HELLO, "--emit-exe"])
        .arg(&output_path)
        .output()
        .expect("run phpc compile --emit-exe with missing runtime archive");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("native runtime archive not found"));
    assert!(output.stdout.is_empty());
    assert!(
        !output_path.exists(),
        "failed compile left stale output at {}",
        output_path.display()
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_emits_linked_native_executable_for_bootstrap_echo() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let runtime_lib = build_runtime_archive();
    let dir = unique_temp_dir("phpc-linked-echo");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let output_path = dir.join("hello-native");

    let interpreted = Command::new(exe)
        .args(["run", BOOTSTRAP_HELLO])
        .output()
        .expect("run phpc interpreter");
    assert!(interpreted.status.success());

    if let Some(system_php) = system_php_output(BOOTSTRAP_HELLO) {
        assert!(
            system_php.status.success(),
            "system PHP failed\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&system_php.stdout),
            String::from_utf8_lossy(&system_php.stderr)
        );
        assert_eq!(system_php.stdout, interpreted.stdout);
        assert_eq!(system_php.stderr, interpreted.stderr);
    }

    let compile = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", &runtime_lib)
        .args(["compile", BOOTSTRAP_HELLO, "--emit-exe"])
        .arg(&output_path)
        .output()
        .expect("compile native executable");
    assert!(
        compile.status.success(),
        "compile failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&compile.stdout),
        String::from_utf8_lossy(&compile.stderr)
    );

    let native = Command::new(&output_path)
        .output()
        .expect("run native executable");
    assert!(native.status.success());
    assert_eq!(native.stdout, interpreted.stdout);
    assert_eq!(native.stderr, interpreted.stderr);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_compile_emits_ir_for_boolean_and_null_echo() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["compile", BOOTSTRAP_BOOL_NULL, "--emit-ir"])
        .output()
        .expect("run phpc compile --emit-ir");

    assert!(
        output.status.success(),
        "compile failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("echo_bool[0] value=true"));
    assert!(stdout.contains("echo_bool[1] value=false"));
    assert!(stdout.contains("echo_null[2]"));
}

#[test]
fn cli_compile_emit_ir_rejects_include_with_truthful_native_diagnostic() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-include-emit-ir");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    std::fs::write(
        &input_path,
        "<?php include 'included.php'; echo 'after include';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-ir")
        .output()
        .expect("run phpc compile --emit-ir");

    let _ = std::fs::remove_dir_all(&dir);

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("native include/require lowering is not implemented for literal path \"included.php\""));
}

#[test]
fn cli_compile_emit_ir_rejects_non_literal_include_path_expression() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-non-literal-include-emit-ir");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    std::fs::write(
        &input_path,
        "<?php include APP_DIR . '/included.php'; echo 'after include';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-ir")
        .output()
        .expect("run phpc compile --emit-ir");

    let _ = std::fs::remove_dir_all(&dir);

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported include statement: expected literal string path"));
}

#[test]
fn cli_compile_emit_ir_rejects_non_literal_require_path_expression() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-non-literal-require-emit-ir");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    std::fs::write(
        &input_path,
        "<?php require APP_DIR . '/included.php'; echo 'after require';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-ir")
        .output()
        .expect("run phpc compile --emit-ir");

    let _ = std::fs::remove_dir_all(&dir);

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported require statement: expected literal string path"));
}

#[test]
fn cli_compile_emit_ir_rejects_include_once_without_claiming_native_include_once() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-include-once-emit-ir");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    std::fs::write(
        &input_path,
        "<?php include_once 'included.php'; echo 'after include_once';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-ir")
        .output()
        .expect("run phpc compile --emit-ir");

    let _ = std::fs::remove_dir_all(&dir);

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr).contains(
        "unsupported include_once statement: include_once/require_once execution is not implemented"
    ));
}

#[test]
fn cli_compile_emit_exe_rejects_require_before_runtime_link_setup() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-require-emit-exe");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    let output_path = dir.join("native-output");
    std::fs::write(&output_path, "stale native output").expect("write stale output");
    std::fs::write(
        &input_path,
        "<?php require 'included.php'; echo 'after require';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", dir.join("missing-libphp_runtime.a"))
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-exe")
        .arg(&output_path)
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("linked native include/require execution is not implemented for literal path \"included.php\""));
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("failed to require literal path"),
        "native compile attempted require execution:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("native runtime archive not found"),
        "unsupported source was masked by runtime setup failure:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !output_path.exists(),
        "failed unsupported compile left stale output at {}",
        output_path.display()
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_compile_emit_exe_rejects_require_once_before_runtime_link_setup() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-require-once-emit-exe");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    let output_path = dir.join("native-output");
    std::fs::write(&output_path, "stale native output").expect("write stale output");
    std::fs::write(
        &input_path,
        "<?php require_once 'included.php'; echo 'after require_once';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", dir.join("missing-libphp_runtime.a"))
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-exe")
        .arg(&output_path)
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr).contains(
        "unsupported require_once statement: include_once/require_once execution is not implemented"
    ));
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("native runtime archive not found"),
        "unsupported source was masked by runtime setup failure:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !output_path.exists(),
        "failed unsupported compile left stale output at {}",
        output_path.display()
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_compile_emit_exe_rejects_missing_literal_include_before_file_execution() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-missing-include-emit-exe");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    let output_path = dir.join("native-output");
    std::fs::write(&output_path, "stale native output").expect("write stale output");
    std::fs::write(
        &input_path,
        "<?php include 'missing.php'; echo 'after include';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", dir.join("missing-libphp_runtime.a"))
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-exe")
        .arg(&output_path)
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("linked native include/require execution is not implemented for literal path \"missing.php\""));
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("failed to include literal path"),
        "native compile attempted include execution:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("native runtime archive not found"),
        "unsupported source was masked by runtime setup failure:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !output_path.exists(),
        "failed unsupported compile left stale output at {}",
        output_path.display()
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_compile_emit_exe_rejects_non_literal_require_before_runtime_link_setup() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let dir = unique_temp_dir("phpc-non-literal-require-emit-exe");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("main.php");
    let output_path = dir.join("native-output");
    std::fs::write(&output_path, "stale native output").expect("write stale output");
    std::fs::write(
        &input_path,
        "<?php require APP_DIR . '/included.php'; echo 'after require';",
    )
    .expect("write php fixture");

    let output = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", dir.join("missing-libphp_runtime.a"))
        .arg("compile")
        .arg(&input_path)
        .arg("--emit-exe")
        .arg(&output_path)
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported require statement: expected literal string path"));
    assert!(
        !String::from_utf8_lossy(&output.stderr).contains("native runtime archive not found"),
        "unsupported source was masked by runtime setup failure:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !output_path.exists(),
        "failed unsupported compile left stale output at {}",
        output_path.display()
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_emits_linked_native_executable_for_boolean_and_null_echo() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let runtime_lib = build_runtime_archive();
    let dir = unique_temp_dir("phpc-linked-bool-null");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let output_path = dir.join("bool-null-native");

    let interpreted = Command::new(exe)
        .args(["run", BOOTSTRAP_BOOL_NULL])
        .output()
        .expect("run phpc interpreter");
    assert!(interpreted.status.success());
    assert_eq!(interpreted.stdout, b"1");

    if let Some(system_php) = system_php_output(BOOTSTRAP_BOOL_NULL) {
        assert!(
            system_php.status.success(),
            "system PHP failed\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&system_php.stdout),
            String::from_utf8_lossy(&system_php.stderr)
        );
        assert_eq!(system_php.stdout, interpreted.stdout);
        assert_eq!(system_php.stderr, interpreted.stderr);
    }

    let compile = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", &runtime_lib)
        .args(["compile", BOOTSTRAP_BOOL_NULL, "--emit-exe"])
        .arg(&output_path)
        .output()
        .expect("compile native executable");
    assert!(
        compile.status.success(),
        "compile failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&compile.stdout),
        String::from_utf8_lossy(&compile.stderr)
    );

    let native = Command::new(&output_path)
        .output()
        .expect("run native executable");
    assert!(native.status.success());
    assert_eq!(native.stdout, interpreted.stdout);
    assert_eq!(native.stderr, interpreted.stderr);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_emits_linked_native_executable_without_semicolon_before_closing_tag() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let runtime_lib = build_runtime_archive();
    let dir = unique_temp_dir("phpc-linked-closing-tag");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("closing-tag.php");
    let output_path = dir.join("closing-tag-native");
    std::fs::write(&input_path, "<?php echo \"closing\\n\" ?>").expect("write php fixture");

    let interpreted = Command::new(exe)
        .arg("run")
        .arg(&input_path)
        .output()
        .expect("run phpc interpreter");
    assert!(interpreted.status.success());
    assert_eq!(interpreted.stdout, b"closing\n");

    if let Some(system_php) = system_php_output(&input_path) {
        assert!(
            system_php.status.success(),
            "system PHP failed\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&system_php.stdout),
            String::from_utf8_lossy(&system_php.stderr)
        );
        assert_eq!(system_php.stdout, interpreted.stdout);
        assert_eq!(system_php.stderr, interpreted.stderr);
    }

    let compile = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", &runtime_lib)
        .arg("compile")
        .arg(&input_path)
        .args(["--emit-exe"])
        .arg(&output_path)
        .output()
        .expect("compile native executable");
    assert!(
        compile.status.success(),
        "compile failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&compile.stdout),
        String::from_utf8_lossy(&compile.stderr)
    );

    let native = Command::new(&output_path)
        .output()
        .expect("run native executable");
    assert!(native.status.success());
    assert_eq!(native.stdout, interpreted.stdout);
    assert_eq!(native.stderr, interpreted.stderr);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_emits_linked_native_executable_without_trailing_newline() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let runtime_lib = build_runtime_archive();
    let dir = unique_temp_dir("phpc-linked-no-newline");
    std::fs::create_dir_all(&dir).expect("create temp dir");
    let input_path = dir.join("no-newline.php");
    let output_path = dir.join("no-newline-native");
    std::fs::write(&input_path, "<?php echo \"closing\" ?>").expect("write php fixture");

    let interpreted = Command::new(exe)
        .arg("run")
        .arg(&input_path)
        .output()
        .expect("run phpc interpreter");
    assert!(interpreted.status.success());
    assert_eq!(interpreted.stdout, b"closing");

    if let Some(system_php) = system_php_output(&input_path) {
        assert!(system_php.status.success());
        assert_eq!(system_php.stdout, interpreted.stdout);
        assert_eq!(system_php.stderr, interpreted.stderr);
    }

    let compile = Command::new(exe)
        .env("PHPC_RUNTIME_LIB", &runtime_lib)
        .arg("compile")
        .arg(&input_path)
        .args(["--emit-exe"])
        .arg(&output_path)
        .output()
        .expect("compile native executable");
    assert!(
        compile.status.success(),
        "compile failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&compile.stdout),
        String::from_utf8_lossy(&compile.stderr)
    );

    let native = Command::new(&output_path)
        .output()
        .expect("run native executable");
    assert!(native.status.success());
    assert_eq!(native.stdout, interpreted.stdout);
    assert_eq!(native.stderr, interpreted.stderr);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn cli_rejects_native_assembly_emission_until_m3_exists() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args([
            "compile",
            BOOTSTRAP_HELLO,
            "--emit-asm",
        ])
        .output()
        .expect("run phpc compile --emit-asm");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("native assembly emission is not implemented yet"));
    assert!(output.stdout.is_empty());
}

#[test]
fn cli_reports_wordpress_bootstrap_general_php_gap() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let root = unique_temp_dir("phpc-wp-bootstrap-check");
    let _ = fs::remove_dir_all(&root);
    fs::create_dir_all(root.join("wp-admin")).expect("create fake wp-admin");
    for entrypoint in [
        "wp-blog-header.php",
        "wp-cron.php",
        "wp-admin/admin-ajax.php",
        "xmlrpc.php",
    ] {
        fs::write(root.join(entrypoint), "<?php echo 'placeholder';").expect("write entrypoint");
    }
    fs::write(
        root.join("wp-settings.php"),
        "<?php\n/**\n * WordPress bootstrap docblock.\n */\ndefine( 'WPINC', 'wp-includes' );\nglobal $wp_version, $wp_db_version;\nrequire ABSPATH . WPINC . '/version.php';",
    )
    .expect("write bootstrap");

    let output = Command::new(exe)
        .arg("wordpress-bootstrap-check")
        .arg(&root)
        .output()
        .expect("run phpc wordpress bootstrap check");

    let _ = fs::remove_dir_all(&root);

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("entrypoint_present=wp-settings.php"));
    assert!(stdout.contains("entrypoint_present=wp-admin/admin-ajax.php"));
    assert!(stdout.contains("status=blocked"));
    assert!(stdout.contains("bootstrap=wp-settings.php"));
    assert!(stdout
        .contains("general_php_gap=unsupported require statement: expected literal string path"));
}

#[test]
fn cli_wordpress_bootstrap_check_rejects_trailing_arguments() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["wordpress-bootstrap-check", "/tmp/nonexistent-wordpress", "--emit-ir"])
        .output()
        .expect("run phpc wordpress bootstrap check");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("unsupported trailing arguments: --emit-ir"));
}

#[test]
fn cli_wordpress_bootstrap_check_requires_root_argument() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .arg("wordpress-bootstrap-check")
        .output()
        .expect("run phpc wordpress bootstrap check");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "");
    assert!(String::from_utf8_lossy(&output.stderr).contains("missing input PHP file"));
}

fn system_php_output(path: impl AsRef<std::ffi::OsStr>) -> Option<std::process::Output> {
    Command::new("php").arg(path).output().ok()
}

fn build_runtime_archive() -> std::path::PathBuf {
    let workspace_root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(std::path::Path::parent)
        .expect("workspace root");
    let mut command = Command::new("cargo");
    command
        .current_dir(workspace_root)
        .args(["build", "-p", "php_runtime", "--lib"]);
    if let Some(target_dir) = std::env::var_os("CARGO_TARGET_DIR") {
        command.env("CARGO_TARGET_DIR", target_dir);
    }
    let output = command.output().expect("build php_runtime staticlib");
    assert!(
        output.status.success(),
        "runtime build failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    let runtime_lib = target_debug_dir().join("libphp_runtime.a");
    assert!(
        runtime_lib.is_file(),
        "runtime archive was not produced at {}",
        runtime_lib.display()
    );
    runtime_lib
}

fn target_debug_dir() -> std::path::PathBuf {
    let mut path = std::env::current_exe().expect("current test executable path");
    assert!(path.pop(), "remove test binary name");
    if path.file_name().is_some_and(|name| name == "deps") {
        assert!(path.pop(), "remove deps directory");
    }
    path
}

fn unique_temp_dir(prefix: &str) -> std::path::PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time after epoch")
        .as_nanos();
    std::env::temp_dir().join(format!("{prefix}-{}-{nanos}", std::process::id()))
}
