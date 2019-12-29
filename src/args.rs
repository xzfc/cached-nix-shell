use std::ffi::OsString;
use std::os::unix::ffi::OsStrExt;
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
    /// true: -p | --packages
    pub packages: bool,
    /// true: --pure; false: --impure
    pub pure: bool,
    /// -i (in shebang)
    pub interpreter: OsString,
    /// --run | --command | --exec (not in shebang)
    pub run: RunMode,
    /// other positional arguments (after --)
    pub rest: Vec<OsString>,
    /// other keyword arguments
    pub other_kw: Vec<OsString>,
}

impl Args {
    pub fn parse(
        args: Vec<OsString>,
        in_shebang: bool,
    ) -> Result<Args, String> {
        let mut res = Args {
            packages: false,
            pure: false,
            interpreter: OsString::from("bash"),
            run: RunMode::InteractiveShell,
            rest: Vec::new(),
            other_kw: Vec::new(),
        };
        let mut it = args.into_iter();
        while let Some(arg) = it.next() {
            let mut next = || -> Result<OsString, String> {
                it.next()
                    .ok_or_else(|| {
                        format!("flag {:?} requires more arguments", arg)
                    })?
                    .clone()
                    .pipe(Ok)
            };
            if arg == "--attr" || arg == "-A" {
                res.other_kw.extend(vec!["-A".into(), next()?]);
            } else if arg == "-I" {
                res.other_kw.extend(vec!["-I".into(), next()?]);
            } else if arg == "--arg" {
                res.other_kw.extend(vec!["--arg".into(), next()?, next()?]);
            } else if arg == "--argstr" {
                res.other_kw
                    .extend(vec!["--argstr".into(), next()?, next()?]);
            } else if arg == "--pure" {
                res.pure = true;
            } else if arg == "--impure" {
                res.pure = false;
            } else if arg == "--packages" || arg == "-p" {
                res.packages = true;
            } else if arg == "-i" && in_shebang {
                res.interpreter = next()?;
            } else if (arg == "--run" || arg == "--command") && !in_shebang {
                res.run = RunMode::Shell(next()?);
            } else if arg == "--exec" && !in_shebang {
                res.run = RunMode::Exec(next()?, it.collect());
                break;
            } else if arg.as_bytes().first() == Some(&b'-') {
                return Err(format!("unexpected arg {:?}", arg));
            } else {
                res.rest.push(arg.clone());
            }
        }
        Ok(res)
    }
}
