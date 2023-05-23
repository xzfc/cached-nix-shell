use std::env::{var, var_os};
use std::path::Path;
use std::process::Command;

fn main() {
    if var_os("CNS_IN_NIX_SHELL").is_none() {
        // Release build triggered by nix-build. Use paths relative to $out.
        let out = var("out").unwrap();
        println!("cargo:rustc-env=CNS_TRACE_NIX_SO={out}/lib/trace-nix.so");
        println!("cargo:rustc-env=CNS_VAR_EMPTY={out}/var/empty");
        println!(
            "cargo:rustc-env=CNS_RCFILE={out}/share/cached-nix-shell/rcfile.sh"
        );
        println!(
            "cargo:rustc-env=CNS_WRAP_PATH={out}/libexec/cached-nix-shell"
        );

        // Use pinned nix and nix-shell binaries.
        println!(
            "cargo:rustc-env=CNS_NIX={}/",
            which::which("nix")
                .expect("command not found: nix")
                .parent()
                .unwrap()
                .as_os_str()
                .to_str()
                .unwrap()
        );
    } else {
        // Developer build triggered by `nix-shell --run 'cargo build'`.
        // Use paths relative to the build directory. Additionally, place
        // trace-nix.so and a symlink to the build directory.
        let out_dir = var("OUT_DIR").unwrap();
        let cmd = Command::new("make")
            .args([
                "-C",
                "nix-trace",
                &format!("DESTDIR={out_dir}"),
                &format!("{out_dir}/trace-nix.so"),
            ])
            .status()
            .unwrap();
        assert!(cmd.success());

        println!("cargo:rustc-env=CNS_TRACE_NIX_SO={out_dir}/trace-nix.so");
        println!("cargo:rustc-env=CNS_VAR_EMPTY=/var/empty");
        println!(
            "cargo:rustc-env=CNS_RCFILE={}/rcfile.sh",
            var("CARGO_MANIFEST_DIR").unwrap()
        );

        if Path::new(&format!("{out_dir}/wrapper")).exists() {
            std::fs::remove_dir_all(format!("{out_dir}/wrapper")).unwrap();
        }
        std::fs::create_dir_all(format!("{out_dir}/wrapper")).unwrap();
        std::os::unix::fs::symlink(
            "../../../../cached-nix-shell",
            format!("{out_dir}/wrapper/nix-shell"),
        )
        .unwrap();
        println!("cargo:rustc-env=CNS_WRAP_PATH={out_dir}/wrapper");

        // Use nix and nix-shell from $PATH at runtime.
        println!("cargo:rustc-env=CNS_NIX=");
    }
}
