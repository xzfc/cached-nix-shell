use bytelines::ByteLinesReader;
use regex::bytes::Regex;
use std::ffi::{OsStr, OsString};
use std::fs::File;
use std::os::unix::ffi::OsStrExt;

/// Parse script in the same way as nix-shell does.
/// Reference: https://github.com/NixOS/nix/blob/2.3.1/src/nix-build/nix-build.cc#L113-L126
pub fn parse_script(fname: &OsStr) -> Option<Vec<OsString>> {
    let re = Regex::new(r#"^#!\s*nix-shell (.*)$"#).unwrap();

    let f = File::open(fname).ok()?;
    let reader = std::io::BufReader::new(&f);
    let mut lines = reader.byte_lines();

    if &lines.next()?.unwrap()[0..2] != b"#!" {
        return None; // First line isn't shebang
    }

    let mut result = Vec::new();

    while let Some(line) = lines.next() {
        let line = line.unwrap();
        if let Some(m) = re.captures(line) {
            let mut items = shellwords(m.get(1).unwrap().as_bytes())
                .into_iter()
                .map(|x| OsStr::from_bytes(&x).to_os_string())
                .collect::<Vec<OsString>>();
            result.append(&mut items);
        }
    }

    Some(result)
}

/// Reference: https://github.com/NixOS/nix/blob/2.3.1/src/nix-build/nix-build.cc#L26-L68
fn shellwords(s: &[u8]) -> Vec<Vec<u8>> {
    let whitespace = Regex::new(r#"^(\s+).*"#).unwrap();
    let mut res = Vec::new();
    let mut it = 0;
    let mut begin = 0;
    let mut cur = Vec::new();
    let mut state = true;
    while it < s.len() {
        if state {
            if let Some(match_) = whitespace.captures(&s[it..]) {
                cur.extend_from_slice(&s[begin..it]);
                res.push(cur);
                cur = Vec::new();
                it += match_.get(1).unwrap().end();
                begin = it;
            }
        }
        match s[it] {
            b'"' => {
                cur.extend_from_slice(&s[begin..it]);
                begin = it + 1;
                state = !state;
            }
            b'\\' => {
                cur.extend_from_slice(&s[begin..it]);
                begin = it + 1;
                it += 1;
            }
            _ => {}
        }
        it += 1;
    }
    cur.extend_from_slice(&s[begin..it]);
    if !cur.is_empty() {
        res.push(cur);
    }
    res
}

#[cfg(test)]
mod tests {
    use super::shellwords;
    macro_rules! v {
        ( $($a:literal),* ) => {{
            vec![ $( Vec::<u8>::from($a as &[_])),* ]
        }}
    }
    #[test]
    fn it_works() {
        assert_eq!(shellwords(b"foo bar baz"), v![b"foo", b"bar", b"baz"],);

        assert_eq!(
            shellwords(br#"foo "bar baz" qoox"#),
            v![b"foo", b"bar baz", b"qoox"],
        );

        assert_eq!(shellwords(br#"foo "bar baz "#), v![b"foo", b"bar baz "],);

        assert_eq!(
            shellwords(br#"foo \"bar baz"#),
            v![b"foo", br#""bar"#, b"baz"],
        );

        assert_eq!(
            shellwords(br#"foo "bar\"baz" qoox"#),
            v![b"foo", br#"bar"baz"#, b"qoox"],
        );

        assert_eq!(
            shellwords(br#"foo bar" "baz qoox"#),
            v![b"foo", b"bar baz", b"qoox"],
        );
    }
}
