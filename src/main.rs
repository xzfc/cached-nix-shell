use serde_json::json;

mod util;

use crypto::digest::Digest;
use crypto::md5::Md5;
use crypto::sha1::Sha1;
use itertools::Itertools;
use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs::{read_link, File};
use std::io::{Read, Write};
use std::os::unix::ffi::OsStrExt;
use tempfile::NamedTempFile;

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
        .filter(|&var| var.len() != 0) // last entry has trailing NUL
        .map(|var| {
            let pos = var.iter().position(|&x| x == b'=').unwrap();
            (
                OsStr::from_bytes(&var[0..pos]).to_owned(),
                OsStr::from_bytes(&var[pos + 1..]).to_owned(),
            )
        })
        .collect::<BTreeMap<_, _>>()
}

fn process_trace(vec: Vec<u8>) -> Option<Vec<u8>> {
    let items = vec
        .split(|&b| b == 0)
        .filter(|&fname| fname.len() != 0) // last entry has trailing NUL
        .tuples::<(_, _)>()
        .collect::<BTreeMap<&[u8], &[u8]>>();

    let mut tmp = OsString::new();

    for (k, v) in items.iter() {
        let fname = OsStr::from_bytes(&k[1..]);
        let res = match k.iter().next() {
            Some(b's') => match nix::sys::stat::lstat(fname) {
                Ok(_) => match nix::fcntl::readlink(fname) {
                    Ok(x) => {
                        tmp = x;
                        tmp.as_os_str()
                    }
                    Err(_) => OsStr::new("+"),
                },
                Err(_) => OsStr::new("-"),
            },
            Some(b'f') => match File::open(fname) {
                Ok(mut file) => {
                    let mut data = Vec::new();
                    file.read_to_end(&mut data).expect("Can't read file");

                    let mut digest = Md5::new();
                    digest.input(&data);

                    tmp = OsString::from(digest.result_str());
                    tmp.as_os_str()
                }
                Err(_) => OsStr::new("-"),
            },
            Some(b'd') => {
                OsStr::new("???") // TODO
            }
            _ => panic!("Unexpected"),
        };

        if res.as_bytes() != *v {
            println!(
                "{:?}: expected {:?}, got {:?}",
                fname,
                OsStr::from_bytes(v),
                res
            );
        }
    }

    let mut result = Vec::<u8>::new();
    for (a, b) in items {
        result.push(0);
        result.extend(a);
        result.push(0);
        result.extend(b);
    }
    Some(result)
}

fn get_clean_env() -> EnvMap {
    let mut clean_env = BTreeMap::new();
    for var in vec!["NIX_PATH", "XDG_RUNTIME_DIR", "TMPDIR"] {
        if let Some(val) = std::env::var_os(var) {
            clean_env.insert(OsString::from(var), OsString::from(val));
        }
    }
    clean_env
}

fn get_shell_env(rest: Vec<&str>, mut clean_env: EnvMap) -> (EnvMap, Option<Vec<u8>>, String) {
    eprintln!("cached-nix-shell: updating cache");

    let trace_file = NamedTempFile::new().expect("can't create temporary file");

    let trace_nix_so = (||
        if option_env!("IN_NIX_SHELL") == Some("impure") {
            std::env::current_exe()
                .ok()?
                .parent()?
                .join("../../nix-trace/build/trace-nix.so")
                .canonicalize()
                .ok()
        } else {
            std::env::current_exe()
                .ok()?
                .parent()?
                .join("../lib/trace-nix.so")
                .canonicalize()
                .ok()
        })();

    if let Some(trace_nix_so) = trace_nix_so {
        clean_env.insert(OsString::from("LD_PRELOAD"), OsString::from(trace_nix_so));
        clean_env.insert(OsString::from("TRACE_NIX"), OsString::from(trace_file.path()));
    } else {
        eprintln!("cached-nix-shell: couldn't find trace-nix.so");
    }

    let env = {
        let mut args = vec!["--pure", "--packages", "--run", "env -0", "--"];
        args.extend(rest);

        let exec = std::process::Command::new("nix-shell")
            .args(args)
            .stderr(std::process::Stdio::inherit())
            .env_clear()
            .envs(clean_env)
            .output()
            .expect("failed to execute nix-shell");
        if !exec.status.success() {
            std::process::exit(exec.status.code().unwrap());
        }
        let mut env = deserealize_env(exec.stdout);
        env.remove(OsStr::new("PWD"));
        env
    };

    let env_out = env
        .get(OsStr::new("out"))
        .expect("expected to have `out` environment variable");

    let mut trace_file = trace_file.reopen().expect("can't reopen temporary file");
    let mut trace_data = Vec::new();
    trace_file.read_to_end(&mut trace_data).expect("Can't read trace file");
    let trace = process_trace(trace_data);
    std::mem::drop(trace_file);

    let drv: String = {
        let exec = std::process::Command::new("nix")
            .args(vec![OsStr::new("show-derivation"), env_out])
            .stderr(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute nix show-derivation");
        if !exec.status.success() {
            std::process::exit(1);
        }
        let output = String::from_utf8(exec.stdout).expect("failed to decode");
        let output: serde_json::Value =
            serde_json::from_str(&output).expect("failed to parse json");

        let (drv, _) = output.as_object().unwrap().into_iter().next().unwrap();

        drv.clone()
    };

    (env, trace, drv)
}

// Parse script in the same way as nix-shell does.
// Reference: src/nix-build/nix-build.cc:112
fn parse_script(fname: &str) -> Option<Vec<String>> {
    use std::io::BufRead;

    let f = File::open(fname).ok()?; // File doesn't exists
    let file = std::io::BufReader::new(&f);

    let mut lines = file.lines().map(|l| l.unwrap());

    if !lines.next()?.starts_with("#!") {
        return None; // First line isn't shebang
    }

    let re = regex::Regex::new(r"^#!\s*nix-shell\s+(.*)$").unwrap();
    let mut args = Vec::new();
    for line in lines {
        if let Some(caps) = re.captures(&line) {
            let line = caps.get(1).unwrap().as_str();
            // XXX: probably rust-shellwords isn't the same as shellwords()
            //      defined in src/nix-build/nix-build.cc.
            let words = shellwords::split(line).expect("Can't shellwords::split");
            args.extend(words);
        }
    }

    Some(args)
}

fn clap_app() -> clap::App<'static, 'static> {
    clap::App::new("cached-nix-shell")
        .version("0.1")
        .setting(clap::AppSettings::TrailingVarArg)
        .arg(
            clap::Arg::with_name("ATTR")
                .short("A")
                .long("attr")
                .takes_value(true),
        )
        .arg(
            clap::Arg::with_name("PACKAGES")
                .short("p")
                .long("--packages"),
        )
        .arg(
            clap::Arg::with_name("COMMAND")
                .long("run")
                .takes_value(true),
        )
        .arg(clap::Arg::with_name("REST").multiple(true))
}

fn clap_app_shebang() -> clap::App<'static, 'static> {
    clap::App::new("cached-nix-shell")
        .setting(clap::AppSettings::TrailingVarArg)
        .arg(
            clap::Arg::with_name("PACKAGES")
                .short("p")
                .long("--packages"),
        )
        .arg(
            clap::Arg::with_name("INTERPRETER")
                .short("i")
                .takes_value(true),
        )
        .arg(clap::Arg::with_name("REST").multiple(true))
}

fn run_script(fname: &str, mut nix_shell_args: Vec<String>, script_args: Vec<String>) {
    nix_shell_args.insert(0, "???".to_string()); // satisfy clap
    let matches = clap_app_shebang().get_matches_from(nix_shell_args);

    let matches_rest = matches.values_of("REST").unwrap().collect::<Vec<&str>>();

    let matches_interpreter = matches.value_of("INTERPRETER").unwrap();

    let env = cached_shell_env(matches_rest);

    {
        let mut interpreter_args = script_args;
        interpreter_args.insert(0, fname.to_string());
        let exec = std::process::Command::new(matches_interpreter)
            .args(interpreter_args)
            .env_clear()
            .envs(&env)
            .status()
            .expect("failed to execute script");
    }
}

fn cached_shell_env(rest: Vec<&str>) -> EnvMap {
    let clean_env = get_clean_env();
    let inputs_json = json!({
        "args": rest.iter().map(|x| x.to_string()).collect::<Vec<String>>(),
        "env": serialize_env(&clean_env),
    })
    .to_string();

    let inputs_hash = {
        let mut hasher = Sha1::new();
        hasher.input_str(&inputs_json);
        hasher.result_str()
    };

    let mut env = if let Some(env) = check_cache(&inputs_hash) {
        env
    } else {
        let (env, trace, drv) = get_shell_env(rest, clean_env);

        cache_write(&inputs_hash, "inputs", &inputs_json.as_bytes().to_vec());
        cache_write(&inputs_hash, "env", &serialize_env(&env));
        if let Some(trace) = trace {
            cache_write(&inputs_hash, "trace", &trace);
        }
        cache_symlink(&inputs_hash, "drv", &drv);
        // TODO: store gcroot
        // TODO: `#! cached-nix-shell --store`

        env
    };

    env.insert(
        OsStr::new("PATH").to_os_string(),
        util::env_path_concat(
            env.get(OsStr::new("PATH")),
            std::env::var_os("PATH").as_ref(),
        ),
    );
    env
}

fn check_cache(hash: &str) -> Option<BTreeMap<OsString, OsString>> {
    let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();

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
    process_trace(trace_buf)?;

    return Some(env);
}

fn cache_write(hash: &str, ext: &str, text: &Vec<u8>) {
    let f = || -> Result<(), std::io::Error> {
        let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
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
        let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
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
    let argv: Vec<String> = std::env::args().into_iter().collect();

    if argv.len() >= 2 {
        let fname = &argv[1];
        if let Some(nix_shell_args) = parse_script(&fname) {
            run_script(
                fname,
                nix_shell_args,
                std::env::args().into_iter().skip(1).collect(),
            );
            std::process::exit(0);
        }
    }

    let matches = clap_app().get_matches();
    let matches_rest = matches.values_of("REST").unwrap().collect::<Vec<&str>>();
    let matches_command = matches.value_of("COMMAND").unwrap();

    let env = cached_shell_env(matches_rest);

    std::process::Command::new("sh")
        .args(vec!["-c", matches_command])
        .env_clear()
        .envs(&env)
        .status()
        .expect("failed to execute script");
}
