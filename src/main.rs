use crate::args::Args;
use crate::bash::is_literal_bash_string;
use crate::path_clean::PathClean;
use crate::trace::Trace;
use itertools::Itertools;
use std::collections::{BTreeMap, HashSet};
use std::env::current_dir;
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
mod bash;
mod path_clean;
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

fn unwrap_or_errx<T>(x: Result<T, String>) -> T {
    match x {
        Ok(x) => x,
        Err(x) => {
            eprintln!("cached-nix-shell: {}", x);
            exit(1)
        }
    }
}

struct NixShellInput {
    pwd: OsString,
    env: EnvMap,
    args: Vec<OsString>,
    weak_args: Vec<OsString>,
}

struct NixShellOutput {
    env: EnvMap,
    trace: trace::Trace,
    drv: String,
}

fn minimal_essential_path() -> OsString {
    let required_binaries = ["nix-shell", "tar", "gzip", "git"];

    let which_dir = |binary: &&str| -> Option<PathBuf> {
        std::env::var_os("PATH")
            .as_ref()
            .unwrap()
            .pipe(std::env::split_paths)
            .find(|dir| {
                nix::unistd::access(
                    &dir.join(binary),
                    nix::unistd::AccessFlags::X_OK,
                )
                .is_ok()
            })
    };

    let required_paths = required_binaries
        .iter()
        .filter_map(which_dir)
        .collect::<HashSet<PathBuf>>();

    // We can't just join_paths(required_paths) -- we need to preserve order
    std::env::var_os("PATH")
        .as_ref()
        .unwrap()
        .pipe(std::env::split_paths)
        .filter(|path_item| required_paths.contains(path_item))
        .unique()
        .pipe(std::env::join_paths)
        .unwrap()
}

fn absolute_dirname(script_fname: &OsStr) -> OsString {
    std::path::PathBuf::from(script_fname)
        .parent()
        .expect("Can't get script dirname")
        .pipe(|parent| {
            if parent.is_absolute() {
                parent.as_os_str().to_os_string()
            } else {
                // We do not use PathBuf::canonicalize() here since we do not
                // want symlink resolving.
                current_dir()
                    .expect("Can't get cwd")
                    .join(parent)
                    .clean()
                    .into_os_string()
            }
        })
}

fn args_to_inp(pwd: OsString, x: &Args) -> NixShellInput {
    let mut args = Vec::new();

    args.push(OsString::from("--pure"));

    let env = {
        let mut clean_env = BTreeMap::new();
        let whitelist = &[
            "HOME",
            "NIX_PATH",
            // tmp dir
            "TMPDIR",
            "XDG_RUNTIME_DIR",
            // ssl-related
            "CURL_CA_BUNDLE",
            "GIT_SSL_CAINFO",
            "NIX_SSL_CERT_FILE",
            "SSL_CERT_FILE",
            // Necessary if nix build caches are accessed via a proxy
            "http_proxy",
            "https_proxy",
        ];
        for var in whitelist {
            if let Some(val) = std::env::var_os(var) {
                clean_env.insert(OsString::from(var), val);
            }
        }
        for var in x.keep.iter() {
            if let Some(val) = std::env::var_os(var) {
                clean_env.insert(var.clone(), val);
                args.push("--keep".into());
                args.push(var.clone());
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
    args.extend(x.other_kw.clone());
    args.push(OsString::from("--"));
    args.extend(x.rest.clone());

    NixShellInput {
        pwd,
        env,
        args,
        weak_args: x.weak_kw.clone(),
    }
}

fn run_nix_shell(inp: &NixShellInput) -> NixShellOutput {
    let trace_file = NamedTempFile::new().expect("can't create temporary file");

    let env = {
        let exec = Command::new("nix-shell")
            .args(&inp.weak_args)
            .args(&inp.args)
            .stderr(std::process::Stdio::inherit())
            .current_dir(&inp.pwd)
            .env_clear()
            .envs(&inp.env)
            .env("LD_PRELOAD", env!("CNS_TRACE_NIX_SO"))
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
        // Drop session variables exported by bash
        env.remove(OsStr::new("OLDPWD"));
        env.remove(OsStr::new("PWD"));
        env.remove(OsStr::new("SHLVL"));
        env.remove(OsStr::new("_"));
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
    let nix_shell_args = Args::parse(nix_shell_args, true).pipe(unwrap_or_errx);
    let inp = args_to_inp(absolute_dirname(&fname), &nix_shell_args);
    let env = cached_shell_env(nix_shell_args.pure, &inp);

    let exec = if is_literal_bash_string(nix_shell_args.interpreter.as_bytes())
    {
        // eprintln!("Interpreter is a literal string, executing directly");
        Command::new(nix_shell_args.interpreter)
            .arg(fname)
            .args(script_args)
            .env_clear()
            .envs(&env)
            .exec()
    } else {
        // eprintln!("Interpreter is bash command, executing 'bash -c'");
        let mut exec_string = OsString::new();
        exec_string.push("exec ");
        exec_string.push(nix_shell_args.interpreter);
        exec_string.push(r#" "$@""#);
        Command::new("bash")
            .arg("-c")
            .arg(exec_string)
            .arg("cached-nix-shell-bash") // corresponds to "$0" inside '-i'
            .arg(fname)
            .args(script_args)
            .env_clear()
            .envs(&env)
            .exec()
    };

    eprintln!("cached-nix-shell: couldn't run: {:?}", exec);
    exit(1);
}

fn run_from_args(args: Vec<OsString>) {
    let mut args = Args::parse(args, false).pipe(unwrap_or_errx);

    let nix_shell_pwd = if args.packages {
        OsString::from(env!("CNS_VAR_EMPTY"))
    } else if let Some(arg) = args.rest.first_mut() {
        let pwd = absolute_dirname(arg);
        *arg = PathBuf::from(&arg)
            .components()
            .next_back()
            .unwrap()
            .pipe(|x| PathBuf::from(".").join(x))
            .into_os_string();
        pwd
    } else {
        // nix-shell will use ./shell.nix or ./default.nix
        current_dir().expect("Can't get cwd").into_os_string()
    };

    let inp = args_to_inp(nix_shell_pwd, &args);
    let env = cached_shell_env(args.pure, &inp);

    let (cmd, cmd_args) = match args.run {
        args::RunMode::InteractiveShell => (
            "bash".into(),
            vec!["--rcfile".into(), env!("CNS_RCFILE").into()],
        ),
        args::RunMode::Shell(cmd) => ("bash".into(), vec!["-c".into(), cmd]),
        args::RunMode::Exec(cmd, cmd_args) => (cmd, cmd_args),
    };

    let exec = Command::new(cmd)
        .args(cmd_args)
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

    let inputs_hash = blake3::hash(&inputs).to_hex().as_str().to_string();

    let mut env = if let Some(env) = check_cache(&inputs_hash) {
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

    env.insert(OsString::from("IN_CACHED_NIX_SHELL"), OsString::from("1"));

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

    // Set to "/no-cert-file.crt" by setup.sh for pure envs.
    env.remove(OsStr::new("SSL_CERT_FILE"));
    env.remove(OsStr::new("NIX_SSL_CERT_FILE"));

    env.insert(OsString::from("IN_NIX_SHELL"), OsString::from("impure"));

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
        if let Some(nix_shell_args) = shebang::parse_script(fname) {
            run_script(
                fname.clone(),
                nix_shell_args,
                std::env::args_os().skip(2).collect(),
            );
        }
    }
    run_from_args(std::env::args_os().skip(1).collect());
}
