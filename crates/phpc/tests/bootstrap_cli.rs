use std::process::Command;

#[test]
fn cli_runs_bootstrap_echo() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args(["run", "../../fixtures/bootstrap/hello.php"])
        .output()
        .expect("run phpc");
    assert!(output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "hello from phpc\n");
}

#[test]
fn cli_rejects_linked_executable_emission_until_m3_exists() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args([
            "compile",
            "../../fixtures/bootstrap/hello.php",
            "--emit-exe",
        ])
        .output()
        .expect("run phpc compile --emit-exe");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("linked native executable emission is not implemented yet"));
    assert!(output.stdout.is_empty());
}

#[test]
fn cli_rejects_native_assembly_emission_until_m3_exists() {
    let exe = env!("CARGO_BIN_EXE_phpc");
    let output = Command::new(exe)
        .args([
            "compile",
            "../../fixtures/bootstrap/hello.php",
            "--emit-asm",
        ])
        .output()
        .expect("run phpc compile --emit-asm");

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("native assembly emission is not implemented yet"));
    assert!(output.stdout.is_empty());
}
