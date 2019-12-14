use std::ffi::{OsStr, OsString};

/// Same as bash's "$a:$b" but in Rust.
pub fn env_path_concat(a: Option<&OsString>, b: Option<&OsString>) -> OsString {
    use std::env::{join_paths, split_paths};
    let a = split_paths(a.map_or(OsStr::new(""), |x| x));
    let b = split_paths(b.map_or(OsStr::new(""), |x| x));
    join_paths(a.chain(b)).unwrap()
}
