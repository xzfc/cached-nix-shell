use std::env::{var, var_os};
use std::path::Path;
use std::process::Command;

fn main() {
    if var_os("CNS_IN_NIX_SHELL").is_none() {
        // Release build triggered by nix-build. Use paths relative to $out.
        let out = var("out").unwrap();
        println!("cargo:rustc-env=CNS_TRACE_NIX_SO={}/lib/trace-nix.so", out);
        println!("cargo:rustc-env=CNS_VAR_EMPTY={}/var/empty", out);
        println!(
            "cargo:rustc-env=CNS_RCFILE={}/share/cached-nix-shell/rcfile.sh",
            out
        );
        println!(
            "cargo:rustc-env=CNS_WRAP_PATH={}/libexec/cached-nix-shell",
            out
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
            .args(&[
                "-C",
                "nix-trace",
                &format!("DESTDIR={}", out_dir),
                &format!("{}/trace-nix.so", out_dir),
            ])
            .status()
            .unwrap();
        assert!(cmd.success());

        println!("cargo:rustc-env=CNS_TRACE_NIX_SO={}/trace-nix.so", out_dir);
        println!("cargo:rustc-env=CNS_VAR_EMPTY=/var/empty");
        println!(
            "cargo:rustc-env=CNS_RCFILE={}/rcfile.sh",
            var("CARGO_MANIFEST_DIR").unwrap()
        );

        if Path::new(&format!("{}/wrapper", out_dir)).exists() {
            std::fs::remove_dir_all(format!("{}/wrapper", out_dir)).unwrap();
        }
        std::fs::create_dir_all(format!("{}/wrapper", out_dir)).unwrap();
        std::os::unix::fs::symlink(
            "../../../../cached-nix-shell",
            format!("{}/wrapper/nix-shell", out_dir),
        )
        .unwrap();
        println!("cargo:rustc-env=CNS_WRAP_PATH={}/wrapper", out_dir);

        // Use nix and nix-shell from $PATH at runtime.
        println!("cargo:rustc-env=CNS_NIX=");
    }
}
