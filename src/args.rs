use std::ffi::OsString;
use std::os::unix::ffi::OsStrExt;

pub struct Args {
    pub packages: bool,
    pub pure: bool,
    pub attr_paths: Vec<OsString>,
    pub interpreter: OsString,
    pub path: Vec<OsString>,
    pub rest: Vec<OsString>,
    pub raw: Vec<OsString>,
    pub run: Option<OsString>,
}

impl Args {
    pub fn parse(args: Vec<OsString>, in_shebang: bool) -> Option<Args> {
        let mut res = Args {
            packages: false,
            pure: false,
            attr_paths: Vec::new(),
            interpreter: OsString::from("bash"),
            path: Vec::new(),
            rest: Vec::new(),
            raw: Vec::new(),
            run: None,
        };
        let mut it = args.iter();
        while let Some(arg) = it.next() {
            if arg == "--attr" || arg == "-A" {
                res.attr_paths.push(it.next()?.clone());
            } else if arg == "--pure" {
                res.pure = true;
            } else if arg == "--impure" {
                res.pure = false;
            } else if arg == "--packages" || arg == "-p" {
                res.packages = true;
            } else if arg == "-i" && in_shebang {
                res.interpreter = it.next()?.clone();
            } else if arg == "-I" {
                res.path.push(it.next()?.clone());
            } else if (arg == "--run" || arg == "--command") && !in_shebang {
                res.run = Some(it.next()?.clone());
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
