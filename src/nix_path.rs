use crate::args::Args;
use std::os::unix::ffi::OsStrExt;

/// True if either $NIX_PATH or -I argument contain a relative path.
pub fn contains_relative_paths(args: &Args) -> bool {
    let nix_path = std::env::var_os("NIX_PATH");
    let nix_path = nix_path.as_deref().map(|x| x.as_bytes()).unwrap_or(b"");

    let include_nix_path = args.include_nix_path.iter().map(|x| x.as_bytes());

    parse_nix_path(nix_path)
        .into_iter()
        .chain(include_nix_path)
        .any(|x| is_relative(x))
}

fn is_relative(b: &[u8]) -> bool {
    let pos = b
        .iter()
        .position(|&c| c == b'=')
        .map(|x| x + 1)
        .unwrap_or(0);
    b.get(pos) != Some(&b'/') && !is_uri(&b[pos..])
}

/// Reference: https://github.com/NixOS/nix/blob/2.3.10/src/libexpr/eval.cc#L242-L277
fn parse_nix_path(s: &[u8]) -> Vec<&[u8]> {
    let mut res = Vec::new();
    let mut p = 0;
    while p < s.len() {
        let start = p;
        let mut start2 = p;

        while p < s.len() && s[p] != b':' {
            if s[p] == b'=' {
                start2 = p + 1;
            }
            p += 1;
        }

        if p == s.len() {
            if p != start {
                res.push(&s[start..p]);
            }
            break;
        }

        if s[p] == b':' {
            if is_uri(&s[start2..]) {
                p += 1;
                while p < s.len() && s[p] != b':' {
                    p += 1;
                }
            }
            res.push(&s[start..p]);
            if p == s.len() {
                break;
            }
        }

        p += 1;
    }

    res
}

/// Reference: https://github.com/NixOS/nix/blob/2.3.10/src/libstore/download.cc#L936-L943
pub fn is_uri(s: &[u8]) -> bool {
    let prefixes = &[
        "channel:",
        "http://",
        "https://",
        "file://",
        "channel://",
        "git://",
        "s3://",
        "ssh://",
    ];
    prefixes
        .iter()
        .any(|prefix| s.starts_with(prefix.as_bytes()))
}

#[cfg(test)]
mod tests {
    use super::{is_relative, parse_nix_path};
    macro_rules! v {
        ( $($a:literal),* ) => {{
            vec![ $( Vec::<u8>::from($a as &[_])),* ]
        }}
    }
    #[test]
    fn it_works() {
        assert_eq!(parse_nix_path(b"foo:bar:baz"), v![b"foo", b"bar", b"baz"]);
        assert_eq!(
            parse_nix_path(b"foo:bar=something:baz"),
            v![b"foo", b"bar=something", b"baz"]
        );
        assert_eq!(
            parse_nix_path(b"foo:bar=https://something:baz"),
            v![b"foo", b"bar=https://something", b"baz"]
        );

        assert_eq!(is_relative(b"foo"), true);
        assert_eq!(is_relative(b"foo=bar"), true);
        assert_eq!(is_relative(b"http://foo"), false);
        assert_eq!(is_relative(b"foo=/bar"), false);
        assert_eq!(is_relative(b"foo=http://bar"), false);
    }
}
