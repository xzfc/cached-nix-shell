use std::env::{var, var_os};
use std::process::Command;

fn main() {
    let out_dir = var("OUT_DIR").unwrap();

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

    if var_os("CARGO_USE_OUT").is_some() {
        println!(
            "cargo:rustc-env=CARGO_TRACE_NIX_SO={}/lib/trace-nix.so",
            var("out").unwrap(),
        );
        println!(
            "cargo:rustc-env=CARGO_VAR_EMPTY={}/var/empty",
            var("out").unwrap(),
        );
        println!(
            "cargo:rustc-env=CARGO_RCFILE={}/share/cached-nix-shell/rcfile.sh",
            var("out").unwrap()
        );
    } else {
        println!(
            "cargo:rustc-env=CARGO_TRACE_NIX_SO={}/trace-nix.so",
            out_dir
        );
        println!("cargo:rustc-env=CARGO_VAR_EMPTY=/var/empty");
        println!(
            "cargo:rustc-env=CARGO_RCFILE={}/rcfile.sh",
            var("CARGO_MANIFEST_DIR").unwrap()
        );
    }
}
