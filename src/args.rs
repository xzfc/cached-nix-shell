use std::ffi::OsString;
use std::os::unix::ffi::OsStrExt;

pub struct Args {
    pub packages: bool,
    pub pure: bool,
    pub interpreter: OsString,
    pub rest: Vec<OsString>,
    pub raw: Vec<OsString>,
}

impl Args {
    pub fn parse(args: Vec<OsString>) -> Option<Args> {
        let mut res = Args {
            packages: false,
            pure: false,
            interpreter: OsString::from("bash"),
            rest: Vec::new(),
            raw: Vec::new(),
        };
        let mut it = args.iter();
        while let Some(arg) = it.next() {
            if arg == "--attr" || arg == "-A" {
                eprintln!("cached-nix-shell: option not implemented: {:?}", arg);
                return None;
            } else if arg == "--pure" {
                res.pure = true;
            } else if arg == "--impure" {
                res.pure = false;
            } else if arg == "--packages" || arg == "-p" {
                res.packages = true;
            } else if arg == "-i" {
                res.interpreter = match it.next() {
                    Some(e) => e.clone(),
                    None => return None,
                };
            } else if arg.as_bytes().first() == Some(&b'-') {
                eprintln!("cached-nix-shell: unexpected arg `{:?}`", arg);
                return None;
            } else {
                res.rest.push(arg.clone());
            }
        }
        res.raw = args;
        Some(res)
    }
}
