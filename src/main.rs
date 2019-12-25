use crate::args::Args;
use crate::trace::Trace;
use crypto::digest::Digest;
use crypto::sha1::Sha1;
use std::collections::{BTreeMap, HashSet};
use std::ffi::{OsStr, OsString};
use std::fs::{read_link, File};
use std::io::{Read, Write};
use std::os::unix::ffi::OsStrExt;
use std::os::unix::process::CommandExt;
use std::os::unix::process::ExitStatusExt;
use std::path::PathBuf;
use std::process::{exit, Command};
use tempfile::NamedTempFile;
use ufcs::Pipe;

mod args;
mod shebang;
mod trace;

type EnvMap = BTreeMap<OsString, OsString>;

/// Serialize environment variables in the same way as `env -0` does.
fn serialize_env(env: &EnvMap) -> Vec<u8> {
    let mut vec = Vec::new();
    for (k, v) in env {
        vec.extend(k.as_bytes());
        vec.push(b'=');
        vec.extend(v.as_bytes());
        vec.push(0);
    }
    vec
}

/// Deserealize environment variables from `env -0` format.
fn deserealize_env(vec: Vec<u8>) -> EnvMap {
    vec.split(|&b| b == 0)
        .filter(|&var| !var.is_empty()) // last entry has trailing NUL
        .map(|var| {
            let pos = var.iter().position(|&x| x == b'=').unwrap();
            (
                OsStr::from_bytes(&var[0..pos]).to_owned(),
                OsStr::from_bytes(&var[pos + 1..]).to_owned(),
            )
        })
        .collect::<BTreeMap<_, _>>()
}

fn serialize_args(args: &[OsString]) -> Vec<u8> {
    let mut vec = Vec::new();
    for arg in args {
        vec.extend(arg.as_bytes());
        vec.push(0);
    }
    vec
}

fn serialize_vecs(vecs: &[&[u8]]) -> Vec<u8> {
    let mut vec = Vec::new();
    for v in vecs {
        vec.extend(format!("{}\0", v.len()).as_str().as_bytes());
        vec.extend(v.iter());
    }
    vec
}

struct NixShellInput {
    pwd: OsString,
    env: EnvMap,
    args: Vec<OsString>,
}

struct NixShellOutput {
    env: EnvMap,
    trace: trace::Trace,
    drv: String,
}

fn minimal_essential_path() -> OsString {
    let required_binaries = &["nix-shell", "tar", "gzip"];

    let clean_path_one = |binary: &&str| -> Option<PathBuf> {
        Some(quale::which(binary)?.parent()?.to_path_buf())
    };

    let required_paths = required_binaries
        .iter()
        .filter_map(clean_path_one)
        .collect::<HashSet<PathBuf>>();

    // We can't just join_paths(required_paths) -- we need to preserve order
    std::env::var_os("PATH")
        .as_ref()
        .unwrap()
        .pipe(std::env::split_paths)
        .filter(|path_item| required_paths.contains(path_item))
        .pipe(std::env::join_paths)
        .unwrap()
}

fn args_to_inp(script_fname: &OsStr, x: &Args) -> NixShellInput {
    let mut args = Vec::new();

    args.push(OsString::from("--pure"));

    let env = {
        let mut clean_env = BTreeMap::new();
        let whitelist =
            &["NIX_PATH", "NIX_SSL_CERT_FILE", "XDG_RUNTIME_DIR", "TMPDIR"];
        for var in whitelist {
            if let Some(val) = std::env::var_os(var) {
                clean_env.insert(OsString::from(var), val);
            }
        }
        clean_env.insert(OsString::from("PATH"), minimal_essential_path());
        clean_env
    };

    if x.packages {
        args.push(OsString::from("--packages"));
    }

    args.push(OsString::from("--run"));
    args.push(OsString::from("env -0"));

    for path in x.path.iter() {
        args.push(OsString::from("-I"));
        args.push(path.clone());
    }

    args.push(OsString::from("--"));
    args.extend(x.rest.clone());

    NixShellInput {
        pwd: std::path::PathBuf::from(script_fname)
            .parent()
            .expect("Can't get script dirname")
            .canonicalize()
            .expect("Can't canonicalize script dirname")
            .as_os_str()
            .to_os_string(),
        env,
        args,
    }
}

fn run_nix_shell(inp: &NixShellInput) -> NixShellOutput {
    let trace_file = NamedTempFile::new().expect("can't create temporary file");

    let env = {
        let exec = Command::new("nix-shell")
            .args(&inp.args)
            .stderr(std::process::Stdio::inherit())
            .env_clear()
            .envs(&inp.env)
            .env("LD_PRELOAD", env!("CARGO_TRACE_NIX_SO"))
            .env("TRACE_NIX", trace_file.path())
            .output()
            .expect("failed to execute nix-shell");
        if !exec.status.success() {
            eprintln!("cached-nix-shell: nix-shell: {}", exec.status);
            let code = exec
                .status
                .code()
                .or_else(|| exec.status.signal().map(|x| x + 127))
                .unwrap_or(255);
            exit(code);
        }
        let mut env = deserealize_env(exec.stdout);
        env.remove(OsStr::new("PWD"));
        env
    };

    let env_out = env
        .get(OsStr::new("out"))
        .expect("expected to have `out` environment variable");

    let mut trace_file =
        trace_file.reopen().expect("can't reopen temporary file");
    let mut trace_data = Vec::new();
    trace_file
        .read_to_end(&mut trace_data)
        .expect("Can't read trace file");
    let trace = Trace::load(trace_data);
    if trace.check_for_changes() {
        eprintln!("cached-nix-shell: some files are already updated, cache won't be reused");
    }
    std::mem::drop(trace_file);

    let drv: String = {
        let exec = Command::new("nix")
            .args(vec![OsStr::new("show-derivation"), env_out])
            .stderr(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute nix show-derivation");
        if !exec.status.success() {
            exit(1);
        }
        let output = String::from_utf8(exec.stdout).expect("failed to decode");
        let output: serde_json::Value =
            serde_json::from_str(&output).expect("failed to parse json");

        let (drv, _) = output.as_object().unwrap().into_iter().next().unwrap();

        drv.clone()
    };

    NixShellOutput { env, trace, drv }
}

fn run_script(
    fname: OsString,
    nix_shell_args: Vec<OsString>,
    script_args: Vec<OsString>,
) {
    let nix_shell_args = Args::parse(nix_shell_args).expect("p");
    let inp = args_to_inp(&fname, &nix_shell_args);
    let env = cached_shell_env(nix_shell_args.pure, &inp);

    let mut interpreter_args = script_args;
    interpreter_args.insert(0, fname);
    let exec = Command::new(nix_shell_args.interpreter)
        .args(interpreter_args)
        .env_clear()
        .envs(&env)
        .exec();
    eprintln!("cached-nix-shell: couldn't run: {:?}", exec);
    exit(1);
}

fn cached_shell_env(pure: bool, inp: &NixShellInput) -> EnvMap {
    let inputs = serialize_vecs(&[
        &serialize_env(&inp.env),
        &serialize_args(&inp.args),
        inp.pwd.as_bytes(),
    ]);

    let inputs_hash = {
        let mut hasher = Sha1::new();
        hasher.input(&inputs);
        hasher.result_str()
    };

    let env = if let Some(env) = check_cache(&inputs_hash) {
        env
    } else {
        eprintln!("cached-nix-shell: updating cache");
        let outp = run_nix_shell(inp);

        // TODO: use flock
        cache_write(&inputs_hash, "inputs", &inputs);
        cache_write(&inputs_hash, "env", &serialize_env(&outp.env));
        cache_write(&inputs_hash, "trace", &outp.trace.serialize());
        cache_symlink(&inputs_hash, "drv", &outp.drv);

        outp.env
    };

    if pure {
        env
    } else {
        merge_env(env)
    }
}

// Merge ambient (impure) environment into cached env.
fn merge_env(mut env: EnvMap) -> EnvMap {
    let mut delim = EnvMap::new();
    delim.insert(OsString::from("PATH"), OsString::from(":"));
    delim.insert(OsString::from("HOST_PATH"), OsString::from(":"));

    for (var, val) in std::env::vars_os() {
        env.entry(var.clone())
            .and_modify(|old_val| {
                if let Some(d) = delim.get(&var) {
                    *old_val = OsString::from(OsStr::from_bytes(
                        &[
                            old_val.as_os_str().as_bytes(),
                            d.as_os_str().as_bytes(),
                            val.as_os_str().as_bytes(),
                        ]
                        .concat(),
                    ));
                }
            })
            .or_insert_with(|| val);
    }
    env
}

fn check_cache(hash: &str) -> Option<BTreeMap<OsString, OsString>> {
    let xdg_dirs =
        xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();

    let env_fname = xdg_dirs.find_cache_file(format!("{}.env", hash))?;
    let drv_fname = xdg_dirs.find_cache_file(format!("{}.drv", hash))?;
    let trace_fname = xdg_dirs.find_cache_file(format!("{}.trace", hash))?;

    let mut env_file = File::open(env_fname).unwrap();
    let mut env_buf = Vec::<u8>::new();
    env_file.read_to_end(&mut env_buf).unwrap();
    let env = deserealize_env(env_buf);

    let drv_store_fname = read_link(drv_fname).ok()?;
    std::fs::metadata(drv_store_fname).ok()?;

    let mut trace_file = File::open(trace_fname).unwrap();
    let mut trace_buf = Vec::<u8>::new();
    trace_file.read_to_end(&mut trace_buf).unwrap();
    let trace = Trace::load(trace_buf);
    if trace.check_for_changes() {
        return None;
    }

    Some(env)
}

fn cache_write(hash: &str, ext: &str, text: &[u8]) {
    let f = || -> Result<(), std::io::Error> {
        let xdg_dirs =
            xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
        let fname = xdg_dirs.place_cache_file(format!("{}.{}", hash, ext))?;
        let mut file = File::create(fname)?;
        file.write_all(text)?;
        Ok(())
    };
    match f() {
        Ok(_) => (),
        Err(e) => eprintln!("Warning: can't store cache: {}", e),
    }
}

fn cache_symlink(hash: &str, ext: &str, target: &str) {
    let f = || -> Result<(), std::io::Error> {
        let xdg_dirs =
            xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
        let fname = xdg_dirs.place_cache_file(format!("{}.{}", hash, ext))?;
        let _ = std::fs::remove_file(&fname);
        std::os::unix::fs::symlink(target, &fname)?;
        Ok(())
    };
    match f() {
        Ok(_) => (),
        Err(e) => eprintln!("Warning: can't symlink to cache: {}", e),
    }
}

fn main() {
    let argv: Vec<OsString> = std::env::args_os().collect();

    if argv.len() >= 2 {
        let fname = &argv[1];
        if let Some(nix_shell_args) = shebang::parse_script(&fname) {
            run_script(
                fname.clone(),
                nix_shell_args,
                std::env::args_os().skip(1).collect(),
            );
        }
    }
    eprintln!("Usage: cached-nix-shell SCRIPT [ARGS]...");
    exit(1);
}
