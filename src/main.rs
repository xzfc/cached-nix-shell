extern crate clap;
#[macro_use]
extern crate serde_json;
extern crate regex;
extern crate serde;
extern crate shellwords;
extern crate xdg;
extern crate crypto;

// Dump environment variables except
fn dump_env() {
    let mut out = serde_json::map::Map::new();
    static IGNORED : [&str; 7] = [
        // Passed to pure as is.
        // 100
        // "HOME", "USER", "LOGNAME", "DISPLAY", "PATH", "TERM", "IN_NIX_SHELL",
        // "TZ", "PAGER", "NIX_BUILD_SHELL", "SHLVL",

        // Added on each nix-shell invocation
        // 386
        "NIX_BUILD_TOP", "TMPDIR", "TEMPDIR", "TMP", "TEMP",
        "NIX_STORE",
        "NIX_BUILD_CORES",
    ];
    for (key, value) in std::env::vars() {
        if IGNORED.contains(&key.as_ref()) {
            continue;
        }
        out.insert(key, json!(value));
    }
    println!("{}", json!(out).to_string());
}

#[derive(Debug, serde::Serialize)]
struct Nope {
    env: std::collections::HashMap<String, String>,
    drv: String,
}

#[derive(Debug, serde::Serialize)]
struct Noope {
    args: Vec::<String>,
    nixpkgs_version: String,
}

fn nope(rest: Vec<&str>) -> Nope {
    let env = {
        let dump_env = {
            let exe = std::env::current_exe().unwrap().into_os_string();
            let exe = match exe.into_string() {
                Ok(x) => x,
                Err(_) => {
                    // TODO: handle invalid UTF-8
                    eprintln!("Error: invalid UTF-8 in absolute path");
                    std::process::exit(1);
                }
            };
            let exe = shellwords::escape(&exe);
            format!("{} --dump-env", &exe)
        };

        let mut args = Vec::<&str>::new();
        args.push("--pure");
        args.push("--packages");

        args.push("--run");
        args.push(&dump_env);

        args.push("--");
        args.extend(rest);

        let exec = std::process::Command::new("nix-shell")
            .args(args)
            .stderr(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute nix-shell");
        if !exec.status.success() {
            std::process::exit(1);
        }
        let output = String::from_utf8(exec.stdout).expect("failed to decode");
        let env : std::collections::HashMap<String, String> =
            serde_json::from_str(&output).expect("failed to parse json");
        env
    };

    let env_out = env.get("out").expect("expected to have `out` environment variable");

    let drv : String = {
        let exec = std::process::Command::new("nix")
            .args(vec!["show-derivation", env_out])
            .stderr(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute nix show-derivation");
        if !exec.status.success() {
            std::process::exit(1);
        }
        let output = String::from_utf8(exec.stdout).expect("failed to decode");
        let output : serde_json::Value =
            serde_json::from_str(&output).expect("failed to parse json");

        let (drv, _) = output.as_object().unwrap().into_iter().next().unwrap();

        drv.clone()
    };

    Nope {
        env: env,
        drv: drv,
    }
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
fn parse_script(fname: &str) -> Option<Vec<String>>  {
    use std::io::BufRead;

    let f = std::fs::File::open(fname).ok()?; // File doesn't exists
    let file = std::io::BufReader::new(&f);

    let mut lines = file.lines().map(|l| l.unwrap()).enumerate();

    {
        let (_, line) = lines.next()?; // Empty file
        if !line.starts_with("#!") {
            None?; // Not shebang
        }
    }

    let re = regex::Regex::new(r"^#!\s*nix-shell\s+(.*)$").unwrap();
    let mut args = Vec::new();
    for (num, line) in lines {
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

fn clap_app() -> clap::App::<'static, 'static> {
    clap::App::new("cached-nix-shell")
        .version("0.1")
        .setting(clap::AppSettings::TrailingVarArg)
        .arg(clap::Arg::with_name("ATTR")
             .short("A")
             .long("attr")
             .takes_value(true))
        .arg(clap::Arg::with_name("PACKAGES")
             .short("p")
             .long("--packages"))
        .arg(clap::Arg::with_name("INTERPRETER")
             .short("i")
             .takes_value(true))
        .arg(clap::Arg::with_name("DUMP")
             .long("dump-env"))
        .arg(clap::Arg::with_name("REST")
             .multiple(true))
}

fn clap_app_shebang() -> clap::App::<'static, 'static> {
    clap::App::new("cached-nix-shell")
        .setting(clap::AppSettings::TrailingVarArg)
        .arg(clap::Arg::with_name("PACKAGES")
             .short("p")
             .long("--packages"))
        .arg(clap::Arg::with_name("INTERPRETER")
             .short("i")
             .takes_value(true))
        .arg(clap::Arg::with_name("REST")
             .multiple(true))
}

fn run_script(fname: &str, mut nix_shell_args: Vec<String>, script_args: Vec<String>) {
    nix_shell_args.insert(0, "???".to_string()); // satisfy clap
    let matches = clap_app_shebang().get_matches_from(nix_shell_args);

    let matches_rest = matches.values_of("REST").unwrap().collect::<Vec<&str>>();

    let matches_interpreter = matches.value_of("INTERPRETER").unwrap();

    let n = cached_nope(matches_rest);

    {
        let mut interpreter_args = script_args;
        interpreter_args.insert(0, fname.to_string());
        let exec = std::process::Command::new(matches_interpreter)
            .args(interpreter_args)
            .env_clear()
            .envs(&n)
            .status()
            .expect("failed to execute script");
    }
}

fn cached_nope(rest: Vec<&str>) -> std::collections::HashMap<String, String> {
    let noope = json!(Noope {
        args: rest.iter().map(|x| x.to_string()).collect(),
        nixpkgs_version: get_nixpkgs_version(),
    }).to_string();

    let nooope_hash = {
        use crate::crypto::digest::Digest;
        let mut hasher = crypto::sha1::Sha1::new();
        hasher.input_str(&noope);
        hasher.result_str()
    };

    if let Some(env) = check_cache(&nooope_hash) {
        return env;
    } else {
        let n = nope(rest);

        cache_write(&nooope_hash, "inputs", noope);
        cache_write(&nooope_hash, "env", json!(n.env).to_string());
        cache_symlink(&nooope_hash, "drv", &n.drv);
        // TODO: store gcroot
        // TODO: `#! cached-nix-shell --store`

        return n.env;
    }
}

fn check_cache(hash: &str) -> Option<std::collections::HashMap<String, String>> {
    let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();

    let env_fname = xdg_dirs.find_cache_file(format!("{}.env", hash))?;
    let drv_fname = xdg_dirs.find_cache_file(format!("{}.drv", hash))?;

    let env_file = std::fs::File::open(env_fname).unwrap();
    let env = serde_json::from_reader(env_file).expect("error parsing json");

    let drv_store_fname = std::fs::read_link(drv_fname).ok()?;
    std::fs::metadata(drv_store_fname).ok()?;

    return Some(env);
}

fn cache_write(hash: &str, ext: &str, text: String) {
    let f = || -> Result<(), std::io::Error> {
        use std::io::Write;
        let xdg_dirs = xdg::BaseDirectories::with_prefix("cached-nix-shell").unwrap();
        let fname = xdg_dirs.place_cache_file(format!("{}.{}", hash, ext))?;
        let mut file = std::fs::File::create(fname)?;
        file.write_all(&text.as_bytes().to_vec())?;
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

    if argv.len() == 2 && argv[1] == "--dump-env" {
        dump_env();
        std::process::exit(0);
    }

    if argv.len() >= 2 {
        let fname = &argv[1];
        if let Some(nix_shell_args) = parse_script(&fname) {
            run_script(fname, nix_shell_args, std::env::args().into_iter().skip(1).collect());
            std::process::exit(0);
        }
    }

    let matches = clap_app().get_matches();
}
