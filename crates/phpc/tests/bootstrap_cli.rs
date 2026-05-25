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

