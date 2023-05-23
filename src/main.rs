use crate::args::Args;
use crate::bash::is_literal_bash_string;
use crate::path_clean::PathClean;
use crate::trace::Trace;
use itertools::Itertools;
use nix::unistd::{access, AccessFlags};
use once_cell::sync::Lazy;
use std::collections::{BTreeMap, HashSet};
use std::env::current_dir;
use std::ffi::{OsStr, OsString};
use std::fs::{read, read_link, File};
use std::io::{Read, Write};
use std::os::unix::ffi::OsStrExt;
use std::os::unix::prelude::OsStringExt;
use std::os::unix::process::CommandExt;
use std::os::unix::process::ExitStatusExt;
use std::path::{Path, PathBuf};
use std::process::{exit, Command, Stdio};
use std::time::Instant;
use tempfile::NamedTempFile;
use ufcs::Pipe;

mod args;
mod bash;
mod nix_path;
mod path_clean;
mod shebang;
mod trace;

type EnvMap = BTreeMap<OsString, OsString>;

struct EnvOptions {
    env: EnvMap,
    bashopts: OsString,
    shellopts: OsString,
}

static XDG_DIRS: Lazy<xdg::BaseDirectories> = Lazy::new(|| {
    xdg::BaseDirectories::with_prefix("cached-nix-shell")
        .expect("Can't get find base cache directory")
});

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
            eprintln!("cached-nix-shell: {x}");
            exit(1)
        }
    }
}

struct NixShellInput {
    pwd: PathBuf,
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
    let required_binaries = ["tar", "gzip", "git"];

    fn which_dir(binary: &&str) -> Option<PathBuf> {
        std::env::var_os("PATH")
            .as_ref()
            .unwrap()
            .pipe(std::env::split_paths)
            .find(|dir| {
                if access(&dir.join(binary), AccessFlags::X_OK).is_err() {
                    return false;
                }

                if binary == &"nix-shell" {
                    // Ignore our fake nix-shell.
                    return !dir
                        .join(binary)
                        .canonicalize()
                        .ok()
                        .and_then(|x| x.file_name().map(|x| x.to_os_string()))
                        .map(|x| x == "cached-nix-shell")
                        .unwrap_or(true);
                }

                true
            })
    }

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

fn absolute_dirname(script_fname: &OsStr) -> PathBuf {
    Path::new(&script_fname)
        .parent()
        .expect("Can't get script dirname")
        .pipe(absolute)
}

fn absolute(path: &Path) -> PathBuf {
    if path.is_absolute() {
        path.to_path_buf()
    } else {
        // We do not use PathBuf::canonicalize() here since we do not want
        // symlink resolving.
        current_dir().expect("Can't get PWD").join(path).clean()
    }
}

fn args_to_inp(pwd: PathBuf, x: &Args) -> NixShellInput {
    let mut args = Vec::new();

    args.push(OsString::from("--pure"));

    let env = {
        let mut clean_env = BTreeMap::new();
        // Env vars to pass to `nix-shell --pure`. Changes to these variables
        // would invalidate the cache.
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
            "ftp_proxy",
            "all_proxy",
            "no_proxy",
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

    let env_file = NamedTempFile::new().expect("can't create temporary file");
    let env_cmd = [
        b"{ printf \"BASHOPTS=%s\\0SHELLOPTS=%s\\0\" \"${BASHOPTS-}\" \"${SHELLOPTS-}\" ; env -0; } >",
        bash::quote(env_file.path().as_os_str().as_bytes()).as_slice(),
    ]
    .concat();

    let env = {
        let status = Command::new(concat!(env!("CNS_NIX"), "nix-shell"))
            .arg("--run")
            .arg(OsStr::from_bytes(&env_cmd))
            .args(&inp.weak_args)
            .args(&inp.args)
            .stderr(std::process::Stdio::inherit())
            .current_dir(&inp.pwd)
            .env_clear()
            .envs(&inp.env)
            .env("LD_PRELOAD", env!("CNS_TRACE_NIX_SO"))
            .env("TRACE_NIX", trace_file.path())
            .stdin(Stdio::null())
            .status()
            .expect("failed to execute nix-shell");
        if !status.success() {
            eprintln!("cached-nix-shell: nix-shell: {status}");
            let code = status
                .code()
                .or_else(|| status.signal().map(|x| x + 127))
                .unwrap_or(255);
            exit(code);
        }
        let mut env = read(env_file.path())
            .expect("can't read an environment file")
            .pipe(deserealize_env);
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
        // nix 2.3
        let mut exec = Command::new(concat!(env!("CNS_NIX"), "nix"))
            .arg("show-derivation")
            .arg(env_out)
            .output()
            .expect("failed to execute nix show-derivation");
        let mut stderr = exec.stderr.clone();
        if !exec.status.success() {
            // nix 2.4
            exec = Command::new(concat!(env!("CNS_NIX"), "nix"))
                .arg("show-derivation")
                .arg("--extra-experimental-features")
                .arg("nix-command")
                .arg(env_out)
                .output()
                .expect("failed to execute nix show-derivation");
            stderr.extend(b"\n");
            stderr.extend(exec.stderr);
        }
        if !exec.status.success() {
            eprintln!(
                "cached-nix-shell: failed to execute nix show-derivation"
            );
            let _ = std::io::stderr().write_all(&stderr);
            exit(1);
        }

        // Path to .drv file is always in ASCII, so no information is lost.
        let output = String::from_utf8_lossy(&exec.stdout);
        let output: serde_json::Value =
            serde_json::from_str(&output).expect("failed to parse json");
        // The first key of the toplevel object contains the path to .drv file.
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
            .envs(&env.env)
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
            .envs(&env.env)
            .exec()
    };

    eprintln!("cached-nix-shell: couldn't run: {exec:?}");
    exit(1);
}

fn run_from_args(args: Vec<OsString>) {
    let mut args = Args::parse(args, false).pipe(unwrap_or_errx);

    // Normalize PWD.
    // References:
    //   https://github.com/NixOS/nix/blob/2.3.10/src/libexpr/common-eval-args.cc#L46-L57
    //   https://github.com/NixOS/nix/blob/2.3.10/src/nix-build/nix-build.cc#L279-L291
    let nix_shell_pwd = if nix_path::contains_relative_paths(&args) {
        // in:  nix-shell -I . ""
        // out: cd $PWD; nix-shell -I . ""
        current_dir().expect("Can't get PWD")
    } else if args.packages_or_expr {
        // in:  nix-shel -p ...
        // out: cd /var/empty; nix-shell -p ...
        PathBuf::from(env!("CNS_VAR_EMPTY"))
    } else if let [arg] = &mut args.rest[..] {
        if arg == "" {
            // in:  nix-shell ""
            // out: cd $PWD; nix-shell ""
            // nix-shell "" will use ./default.nix
            current_dir().expect("Can't get PWD")
        } else if arg.as_bytes().starts_with(b"<")
            && arg.as_bytes().ends_with(b">")
            || nix_path::is_uri(arg.as_bytes())
        {
            // in:  nix-shell '<foo>'
            // out: cd /var/empty; nix-shell '<foo>'
            // in:  nix-shell http://...
            // out: cd /var/empty; nix-shell http://...
            PathBuf::from(env!("CNS_VAR_EMPTY"))
        } else if arg.as_bytes().ends_with(b"/") || Path::new(arg).is_dir() {
            // in:  nix-shell /path/to/dir
            // out: cd /path/to/dir; nix-shell .
            let pwd = absolute(Path::new(arg));
            *arg = OsString::from(".");
            pwd
        } else {
            // in:  nix-shell /path/to/file
            // out: cd /path/to; nix-shell ./file
            let pwd = absolute_dirname(arg);
            *arg = PathBuf::from(&arg)
                .components()
                .next_back()
                .unwrap()
                .pipe(|x| PathBuf::from(".").join(x))
                .into_os_string();
            pwd
        }
    } else {
        // in:  nix-shell
        // out: cd $PWD; nix-shell
        // nix-shell will use ./shell.nix or ./default.nix
        // in:  nix-shell foo.nix bar.nix ...
        current_dir().expect("Can't get PWD")
    };

    let inp = args_to_inp(nix_shell_pwd, &args);
    let env = cached_shell_env(args.pure, &inp);

    let mut bash_args = Vec::new();
    // XXX: only check for options that are set by current stdenv and nix-shell.
    env.bashopts
        .as_bytes()
        .split(|&b| b == b':')
        .filter(|opt| {
            [b"execfail".as_ref(), b"inherit_errexit", b"nullglob"]
                .contains(opt)
        })
        .for_each(|opt| {
            bash_args.extend_from_slice(&[
                "-O".into(),
                OsString::from_vec(opt.to_vec()),
            ])
        });
    env.shellopts
        .as_bytes()
        .split(|&b| b == b':')
        .filter(|opt| [b"pipefail".as_ref()].contains(opt))
        .for_each(|opt| {
            bash_args.extend_from_slice(&[
                "-o".into(),
                OsString::from_vec(opt.to_vec()),
            ])
        });

    let (cmd, cmd_args) = match args.run {
        args::RunMode::InteractiveShell => {
            bash_args.extend_from_slice(&[
                "--rcfile".into(),
                env!("CNS_RCFILE").into(),
            ]);
            ("bash".into(), bash_args)
        }
        args::RunMode::Shell(cmd) => {
            bash_args.extend_from_slice(&["-c".into(), cmd]);
            ("bash".into(), bash_args)
        }
        args::RunMode::Exec(cmd, cmd_args) => (cmd, cmd_args),
    };

    let exec = Command::new(cmd)
        .args(cmd_args)
        .env_clear()
        .envs(&env.env)
        .exec();
    eprintln!("cached-nix-shell: couldn't run: {exec:?}");
    exit(1);
}

fn cached_shell_env(pure: bool, inp: &NixShellInput) -> EnvOptions {
    let inputs = serialize_vecs(&[
        &serialize_env(&inp.env),
        &serialize_args(&inp.args),
        inp.pwd.as_os_str().as_bytes(),
    ]);

    let inputs_hash = blake3::hash(&inputs).to_hex().as_str().to_string();

    let mut env = if let Some(env) = check_cache(&inputs_hash) {
        env
    } else {
        eprintln!("cached-nix-shell: updating cache");
        let start = Instant::now();
        let outp = run_nix_shell(inp);
        eprintln!("cached-nix-shell: done in {:?}", start.elapsed());

        // TODO: use flock
        cache_write(&inputs_hash, "inputs", &inputs);
        cache_write(&inputs_hash, "env", &serialize_env(&outp.env));
        cache_write(&inputs_hash, "trace", &outp.trace.serialize());
        cache_symlink(&inputs_hash, "drv", &outp.drv);

        outp.env
    };

    let shellopts = env.remove(OsStr::new("SHELLOPTS")).unwrap_or_default();
    let bashopts = env.remove(OsStr::new("BASHOPTS")).unwrap_or_default();
    env.insert(OsString::from("IN_CACHED_NIX_SHELL"), OsString::from("1"));

    EnvOptions {
        env: merge_env(if pure { env } else { merge_impure_env(env) }),
        shellopts,
        bashopts,
    }
}

// Merge ambient (impure) environment into cached env.
fn merge_impure_env(mut env: EnvMap) -> EnvMap {
    let mut delim = EnvMap::new();
    delim.insert(OsString::from("PATH"), OsString::from(":"));
    delim.insert(OsString::from("HOST_PATH"), OsString::from(":"));
    delim.insert(OsString::from("XDG_DATA_DIRS"), OsString::from(":"));

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

fn merge_env(mut env: EnvMap) -> EnvMap {
    // These variables are always passed by the original nix-shell, regardless
    // of the --pure flag.
    let keep = &[
        "USER",
        "LOGNAME",
        "DISPLAY",
        "WAYLAND_DISPLAY",
        "WAYLAND_SOCKET",
        "TERM",
        "NIX_SHELL_PRESERVE_PROMPT",
        "TZ",
        "PAGER",
        "SHLVL",
    ];
    for var in keep {
        if let Some(vel) = std::env::var_os(var) {
            env.insert(OsString::from(var), vel);
        }
    }
    env
}

fn check_cache(hash: &str) -> Option<BTreeMap<OsString, OsString>> {
    let env_fname = XDG_DIRS.find_cache_file(format!("{hash}.env"))?;
    let drv_fname = XDG_DIRS.find_cache_file(format!("{hash}.drv"))?;
    let trace_fname = XDG_DIRS.find_cache_file(format!("{hash}.trace"))?;

    let env = read(env_fname).unwrap().pipe(deserealize_env);

    let drv_store_fname = read_link(drv_fname).ok()?;
    std::fs::metadata(drv_store_fname).ok()?;

    let trace = read(trace_fname).unwrap().pipe(Trace::load);
    if trace.check_for_changes() {
        return None;
    }

    Some(env)
}

fn cache_write(hash: &str, ext: &str, text: &[u8]) {
    let f = || -> Result<(), std::io::Error> {
        let fname = XDG_DIRS.place_cache_file(format!("{hash}.{ext}"))?;
        let mut file = File::create(fname)?;
        file.write_all(text)?;
        Ok(())
    };
    match f() {
        Ok(_) => (),
        Err(e) => eprintln!("Warning: can't store cache: {e}"),
    }
}

fn cache_symlink(hash: &str, ext: &str, target: &str) {
    let f = || -> Result<(), std::io::Error> {
        let fname = XDG_DIRS.place_cache_file(format!("{hash}.{ext}"))?;
        let _ = std::fs::remove_file(&fname);
        std::os::unix::fs::symlink(target, &fname)?;
        Ok(())
    };
    match f() {
        Ok(_) => (),
        Err(e) => eprintln!("Warning: can't symlink to cache: {e}"),
    }
}

fn wrap(cmd: Vec<OsString>) {
    if cmd.is_empty() {
        eprintln!("cached-nix-shell: command not specified");
        eprintln!("usage: cached-nix-shell --wrap COMMAND ARGS...");
        exit(1);
    }

    if access(
        Path::new(&format!("{}/nix-shell", env!("CNS_WRAP_PATH"))),
        AccessFlags::X_OK,
    )
    .is_err()
    {
        eprintln!(
            "cached-nix-shell: couldn't wrap, {}/nix-shell is not executable",
            env!("CNS_WRAP_PATH")
        );
        exit(1);
    }

    let new_path = [
        env!("CNS_WRAP_PATH").as_bytes(),
        b":",
        std::env::var_os("PATH").unwrap().as_bytes(),
    ]
    .concat();

    let exec = Command::new(&cmd[0])
        .args(&cmd[1..])
        .env("PATH", OsStr::from_bytes(&new_path))
        .exec();
    eprintln!("cached-nix-shell: couldn't run: {exec}");
    exit(1);
}

fn main() {
    let argv: Vec<OsString> = std::env::args_os().collect();

    if argv.len() >= 2 && argv[1] == "--wrap" {
        wrap(std::env::args_os().skip(2).collect());
    }

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
