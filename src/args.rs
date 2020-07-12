//! nix-shell argument parsing
//!
//! While `cached-nix-shell` passes most of its arguments to `nix-shell` as-is
//! without even looking into them, there are some arguments that should be
//! extracted and processed by `cached-nix-shell` itself.  In order to do so, we
//! still need to parse the whole command line.
//!
//! **Q:** Why not just use a library like `clap` or `docopts`?
//! **A:** We need to emulate quirks of nix-shell argument parsing in a 100%
//! compatible way, so it is appropriate to code this explicitly rather than use
//! such libraries.

use std::collections::VecDeque;
use std::ffi::{OsStr, OsString};
use std::os::unix::ffi::OsStrExt;
use std::process::exit;
use ufcs::Pipe;

pub enum RunMode {
    /// no arg
    InteractiveShell,
    /// --run CMD | --command CMD
    Shell(OsString),
    /// --exec CMD ARGS...
    Exec(OsString, Vec<OsString>),
}

pub struct Args {
    /// true: -p | --packages | -E | --expr
    pub packages_or_expr: bool,
    /// true: --pure; false: --impure
    pub pure: bool,
    /// -i (in shebang)
    pub interpreter: OsString,
    /// --run | --command | --exec (not in shebang)
    pub run: RunMode,
    /// --keep
    pub keep: Vec<OsString>,
    /// other positional arguments (after --)
    pub rest: Vec<OsString>,
    /// other keyword arguments
    pub other_kw: Vec<OsString>,
    /// weak keyword arguments
    pub weak_kw: Vec<OsString>,
}

struct NixShellOption {
    /// true if adding or removing this option should not invalidate the cache
    is_weak: bool,
    arg_count: u8,
    names: &'static [&'static str],
}

const fn opt(
    is_weak: bool,
    arg_count: u8,
    names: &'static [&'static str],
) -> NixShellOption {
    NixShellOption {
        is_weak,
        arg_count,
        names,
    }
}

const OPTIONS_DB: &[NixShellOption] = &[
    opt(false, 1, &["--attr", "-A"]),
    opt(false, 1, &["-I"]),
    opt(false, 2, &["--arg"]),
    opt(false, 2, &["--argstr"]),
    opt(true, 0, &["--fallback"]),
    opt(true, 0, &["--keep-failed", "-K"]),
    opt(true, 0, &["--keep-going", "-k"]),
    opt(true, 0, &["--no-build-hook"]),
    opt(true, 0, &["--no-build-output", "-Q"]),
    opt(true, 0, &["--quiet"]),
    opt(true, 0, &["--repair"]),
    opt(true, 0, &["--show-trace"]),
    opt(true, 0, &["--verbose", "-v"]),
    opt(true, 1, &["--cores"]),
    opt(true, 1, &["--max-jobs", "-j"]),
    opt(true, 1, &["--max-silent-time"]),
    opt(true, 1, &["--timeout"]),
    opt(true, 2, &["--option"]),
];

impl Args {
    pub fn parse(
        args: Vec<OsString>,
        in_shebang: bool,
    ) -> Result<Args, String> {
        let mut res = Args {
            packages_or_expr: false,
            pure: false,
            interpreter: OsString::from("bash"),
            run: RunMode::InteractiveShell,
            keep: Vec::new(),
            rest: Vec::new(),
            other_kw: Vec::new(),
            weak_kw: Vec::new(),
        };
        let mut it = VecDeque::<OsString>::from(args);
        while let Some(arg) = get_next_arg(&mut it) {
            let mut next = || -> Result<OsString, String> {
                it.pop_front()
                    .ok_or_else(|| {
                        format!("flag {:?} requires more arguments", arg)
                    })?
                    .pipe(Ok)
            };
            if let Some(db_item) = OPTIONS_DB
                .iter()
                .find(|it| it.names.iter().any(|&x| arg == x))
            {
                let vec = if db_item.is_weak {
                    &mut res.weak_kw
                } else {
                    &mut res.other_kw
                };
                vec.push(db_item.names[0].into());
                for _ in 0..db_item.arg_count {
                    vec.push(next()?);
                }
            } else if arg == "--pure" {
                res.pure = true;
            } else if arg == "--impure" {
                res.pure = false;
            } else if arg == "-p"
                || arg == "--packages"
                || arg == "-E"
                || arg == "--expr"
            {
                res.packages_or_expr = true;
                res.other_kw.push(arg);
            } else if arg == "-i" && in_shebang {
                res.interpreter = next()?;
            } else if (arg == "--run" || arg == "--command") && !in_shebang {
                res.run = RunMode::Shell(next()?);
            } else if arg == "--exec" && !in_shebang {
                res.run = RunMode::Exec(next()?, it.into());
                break;
            } else if arg == "--keep" {
                res.keep.push(next()?);
            } else if arg == "--version" {
                exit_version();
            } else if arg == "--wrap" && !in_shebang {
                return Err("--wrap should be the first argument".to_string());
            } else if arg.as_bytes().first() == Some(&b'-') {
                return Err(format!("unexpected arg {:?}", arg));
            } else {
                res.rest.push(arg.clone());
            }
        }
        Ok(res)
    }
}

fn get_next_arg(it: &mut VecDeque<OsString>) -> Option<OsString> {
    let arg = it.pop_front()?;
    let argb = arg.as_bytes();
    if argb.len() > 2 && argb[0] == b'-' && is_alpha(argb[1]) {
        // Expand short options and put them back to the deque.
        // Reference: https://github.com/NixOS/nix/blob/2.3.1/src/libutil/args.cc#L29-L42

        let split_idx = argb[1..]
            .iter()
            .position(|&b| !is_alpha(b))
            .unwrap_or(argb.len() - 1);
        // E.g. "-pj16" -> ("pj", "16")
        let (letters, rest) = argb[1..].split_at(split_idx);

        if !rest.is_empty() {
            it.push_front(OsStr::from_bytes(rest).into());
        }
        for &c in letters.iter().rev() {
            it.push_front(OsStr::from_bytes(&[b'-', c]).into());
        }

        it.pop_front()
    } else {
        Some(arg)
    }
}

fn is_alpha(b: u8) -> bool {
    b'a' <= b && b <= b'z' || b'A' <= b && b <= b'Z'
}

fn exit_version() {
    println!(
        "cached-nix-shell v{}{}",
        env!("CARGO_PKG_VERSION"),
        option_env!("CNS_GIT_COMMIT")
            .map(|x| format!("-{}", x))
            .unwrap_or("".into())
    );
    exit(0);
}

#[cfg(test)]
mod test {
    use super::*;
    /// Expand an arg using `get_next_arg`
    fn expand(arg: &str) -> Vec<String> {
        let mut it: VecDeque<OsString> = VecDeque::from(vec![arg.into()]);
        std::iter::from_fn(|| get_next_arg(&mut it))
            .map(|s| s.to_string_lossy().into())
            .collect()
    }
    #[test]
    fn test_get_next_arg() {
        assert_eq!(expand("--"), vec!["--"]);
        assert_eq!(expand("default.nix"), vec!["default.nix"]);
        assert_eq!(expand("--argstr"), vec!["--argstr"]);
        assert_eq!(expand("-pi"), vec!["-p", "-i"]);
        assert_eq!(expand("-j4"), vec!["-j", "4"]);
        assert_eq!(expand("-j16"), vec!["-j", "16"]);
        assert_eq!(expand("-pj16"), vec!["-p", "-j", "16"]);
    }
}
