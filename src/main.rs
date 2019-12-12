use serde_json::json;

mod util;
mod run;

use std::ffi::{OsStr, OsString};
use std::collections::HashMap;

type EnvMap = HashMap<OsString, OsString>;

/// Serialize environment variables in the same way as `env -0` does.
fn serialize_env(env: &EnvMap) -> Vec<u8> {
    let mut vec = Vec::new();
    for (k, v) in env {
        use std::os::unix::ffi::OsStrExt;
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
        .filter(|&var| var.len() != 0) // last var has trailing space
        .map(|var| {
            use std::os::unix::ffi::OsStrExt;
            let pos = var.iter().position(|&x| x == b'=').unwrap();
            (
                OsStr::from_bytes(&var[0..pos]).to_owned(),
                OsStr::from_bytes(&var[pos + 1..]).to_owned(),
            )
        })
        .collect::<HashMap<_, _>>()
}

fn get_shell_env(rest: Vec<&str>) -> (EnvMap, String) {
    let env = {
        let mut args = vec!["--pure", "--packages", "--run", "env -0", "--"];
        args.extend(rest);

        let exec = std::process::Command::new("nix-shell")
            .args(args)
            .stderr(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute nix-shell");
        if !exec.status.success() {
            std::process::exit(1);
        }
        let mut env = deserealize_env(exec.stdout);

        static IGNORED: [&str; 7] = [
            // Passed by `nix-shell --pure` as is.
            // Reference: src/nix-build/nix-build.cc:100
            // "HOME", "USER", "LOGNAME", "DISPLAY", "PATH", "TERM", "IN_NIX_SHELL",
            // "TZ", "PAGER", "NIX_BUILD_SHELL", "SHLVL",
            // TODO: handle PATH
            // TODO: preserve other vars

            // Added on each nix-shell invocation.
            // Reference: src/nix-build/nix-build.cc:386
            "NIX_BUILD_TOP",
            "TMPDIR",
            "TEMPDIR",
            "TMP",
            "TEMP",
            "NIX_STORE",
            "NIX_BUILD_CORES",
        ];

        for i in IGNORED.iter() {
            env.remove(OsStr::new(i));
        }
        env
    };

    let env_out = env
        .get(OsStr::new("out"))
        .expect("expected to have `out` environment variable");

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

    (env, drv)
}

fn get_nixpkgs_version() -> String {
    let exec = std::process::Command::new("nix-instantiate")
        .args(vec!["--find-file", "nixpkgs"])
        .stderr(std::process::Stdio::inherit())
        .output()
        .expect("failed to execute nix-instantiate");
    if !exec.status.success() {
        std::process::exit(1);
    }
    let output = String::from_utf8(exec.stdout).expect("failed to decode");
    format!("{}/.version-suffix", output)
}

// Parse script in the same way as nix-shell does.
// Reference: src/nix-build/nix-build.cc:112
fn parse_script(fname: &str) -> Option<Vec<String>> {
    use std::io::BufRead;

    let f = std::fs::File::open(fname).ok()?; // File doesn't exists
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
            clap::Arg::with_name("INTERPRETER")
                .short("i")
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

    let mut env = cached_shell_env(matches_rest);
    {
        env.insert(OsStr::new("PATH").to_os_string(),
            util::env_path_concat(
                env.get(OsStr::new("PATH")),
                std::env::var_os("PATH").as_ref(),
            ));
    }
    
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
    let inputs_json = json!({
        "args": rest.iter().map(|x| x.to_string()).collect::<Vec<String>>(),
        "nixpkgs_version": get_nixpkgs_version(),
    })
    .to_string();

    let inputs_hash = {
        use crypto::digest::Digest;
        let mut hasher = crypto::sha1::Sha1::new();
        hasher.input_str(&inputs_json);
        hasher.result_str()
    };

    if let Some(env) = check_cache(&inputs_hash) {
        return env;
    } else {
        let (env, drv) = get_shell_env(rest);

        cache_write(&inputs_hash, "inputs", &inputs_json.as_bytes().to_vec());
        cache_write(&inputs_hash, "env", &serialize_env(&env));
        cache_symlink(&inputs_hash, "drv", &drv);
        // TODO: store gcroot
        // TODO: `#! cached-nix-shell --store`

        return env;
    }
}

fn check_cache(hash: &str) -> Option<HashMap<OsString, OsString>> {
    let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();

    let env_fname = xdg_dirs.find_cache_file(format!("{}.env", hash))?;
    let drv_fname = xdg_dirs.find_cache_file(format!("{}.drv", hash))?;

    let mut env_file = std::fs::File::open(env_fname).unwrap();
    let mut env_buf = Vec::<u8>::new();
    {
        use std::io::Read;
        env_file.read_to_end(&mut env_buf).unwrap();
    }
    let env = deserealize_env(env_buf);

    let drv_store_fname = std::fs::read_link(drv_fname).ok()?;
    std::fs::metadata(drv_store_fname).ok()?;

    return Some(env);
}

fn cache_write(hash: &str, ext: &str, text: &Vec<u8>) {
    let f = || -> Result<(), std::io::Error> {
        use std::io::Write;
        let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
        let fname = xdg_dirs.place_cache_file(format!("{}.{}", hash, ext))?;
        let mut file = std::fs::File::create(fname)?;
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
    /*
    run::run_drv(
        "/nix/store/w3wc1w1z6gbvdn6z8yy7qpqkab4gdcrw-stdenv-linux.drv",
        vec!["true".to_string()]
        );
    */
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
}
