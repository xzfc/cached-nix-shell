// Why I find [path_clean] crate unsuitable: since it operates on str/String, it
// assumes that paths are valid utf8 strings.  My implementation operates on
// Path/PathBuf/OsStr thus it doesn't make any assumptions.
// [path_clean]: https://docs.rs/path-clean/0.1.0/path_clean/

use std::ffi::OsStr;
use std::path::{Path, PathBuf};

pub trait PathClean {
    fn clean(&self) -> PathBuf;
}

impl PathClean for Path {
    fn clean(&self) -> PathBuf {
        let mut res = Vec::new();
        for elem in self {
            if elem == "/" {
                res.push(elem);
            } else if elem == "." {
                // do nothing
            } else if elem == ".." {
                if res.last().is_none() || res.last() == Some(&OsStr::new(".."))
                {
                    res.push(elem);
                } else if res.last() == Some(&OsStr::new("/")) {
                    // do nothing
                } else {
                    res.pop();
                }
            } else {
                res.push(elem);
            }
        }
        if res.is_empty() {
            res.push(OsStr::new("."));
        }
        res.into_iter().collect()
    }
}

#[test]
fn path_clean_test() {
    // Taken from https://golang.org/src/path/path_test.go
    let cases = [
        // Already clean
        ("", "."),
        ("abc", "abc"),
        ("abc/def", "abc/def"),
        ("a/b/c", "a/b/c"),
        (".", "."),
        ("..", ".."),
        ("../..", "../.."),
        ("../../abc", "../../abc"),
        ("/abc", "/abc"),
        ("/", "/"),
        // Remove trailing slash
        ("abc/", "abc"),
        ("abc/def/", "abc/def"),
        ("a/b/c/", "a/b/c"),
        ("./", "."),
        ("../", ".."),
        ("../../", "../.."),
        ("/abc/", "/abc"),
        // Remove doubled slash
        ("abc//def//ghi", "abc/def/ghi"),
        ("//abc", "/abc"),
        ("///abc", "/abc"),
        ("//abc//", "/abc"),
        ("abc//", "abc"),
        // Remove . elements
        ("abc/./def", "abc/def"),
        ("/./abc/def", "/abc/def"),
        ("abc/.", "abc"),
        // Remove .. elements
        ("abc/def/ghi/../jkl", "abc/def/jkl"),
        ("abc/def/../ghi/../jkl", "abc/jkl"),
        ("abc/def/..", "abc"),
        ("abc/def/../..", "."),
        ("/abc/def/../..", "/"),
        ("abc/def/../../..", ".."),
        ("/abc/def/../../..", "/"),
        ("abc/def/../../../ghi/jkl/../../../mno", "../../mno"),
        // Combinations
        ("abc/./../def", "def"),
        ("abc//./../def", "def"),
        ("abc/../../././../def", "../../def"),
    ];

    for (path, result) in cases.iter() {
        assert_eq!(Path::new(path).clean(), Path::new(result));
        assert_eq!(Path::new(result).clean(), Path::new(result));
    }
}
