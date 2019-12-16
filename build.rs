use std::env;
use std::process::Command;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();

    let cmd = Command::new("gcc")
        .args(&[
            "-fPIC",
            "-shared",
            "-o",
            &format!("{}/trace-nix.so", out_dir),
            "nix-trace/trace-nix.c",
        ])
        .status()
        .unwrap();
    assert!(cmd.success());

    if env::var_os("CARGO_USE_OUT").is_some() {
        println!(
            "cargo:rustc-env=CARGO_TRACE_NIX_SO={}/lib/{}.out/trace-nix.so",
            env::var("out").unwrap(),
            env::var("CARGO_PKG_NAME").unwrap(),
        );
    } else {
        println!(
            "cargo:rustc-env=CARGO_TRACE_NIX_SO={}/trace-nix.so",
            out_dir
        );
    }
}
