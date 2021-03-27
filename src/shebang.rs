use bytelines::ByteLinesReader;
use std::ffi::{OsStr, OsString};
use std::fs::File;
use std::os::unix::ffi::OsStrExt;

/// Parse script in the same way as nix-shell does.
/// Reference: https://github.com/NixOS/nix/blob/2.3.1/src/nix-build/nix-build.cc#L113-L126
pub fn parse_script(fname: &OsStr) -> Option<Vec<OsString>> {
    let f = File::open(fname).ok()?;
    let reader = std::io::BufReader::new(&f);
    let mut lines = reader.byte_lines();

    if !lines.next()?.ok()?.starts_with(b"#!") {
        return None; // First line isn't shebang
    }

    let mut result = Vec::new();

    while let Some(line) = lines.next() {
        let line = line.unwrap();
        if let Some(m) = re_nix_shell(line) {
            let mut items = shellwords(m)
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
    let mut res = Vec::new();
    let mut it = 0;
    let mut begin = 0;
    let mut cur = Vec::new();
    let mut state = true;
    loop {
        if state {
            if let Some(match_len) = re_whitespaces_len(&s[it..]) {
                cur.extend_from_slice(&s[begin..it]);
                res.push(cur);
                cur = Vec::new();
                it += match_len;
                begin = it;
            }
        }
        match s.get(it) {
            Some(b'"') => {
                cur.extend_from_slice(&s[begin..it]);
                begin = it + 1;
                state = !state;
            }
            Some(b'\\') => {
                cur.extend_from_slice(&s[begin..it]);
                begin = it + 1;
                it += 1;
            }
            Some(_) => {}
            None => break,
        }
        it += 1;
    }
    cur.extend_from_slice(&s[begin..it]);
    if !cur.is_empty() {
        res.push(cur);
    }
    res
}

/// Characters that are matched by `\s` or isspace(3).
const SPACES: &[u8; 6] = &[9, 10, 11, 12, 13, 32];

/// Match C++'s `std::regex("^#!\\s*nix-shell (.*)$")` and return `\1`
fn re_nix_shell(mut line: &[u8]) -> Option<&[u8]> {
    if !line.starts_with(b"#!") {
        return None;
    }
    line = &line[b"#!".len()..];

    while line.first().map(|c| SPACES.contains(c)) == Some(true) {
        line = &line[1..];
    }

    if !line.starts_with(b"nix-shell ") {
        return None;
    }
    line = &line[b"nix-shell ".len()..];

    Some(line)
}

/// Match C++'s `std::regex("^(\\s+).*")` and return length of `\1`
fn re_whitespaces_len(line: &[u8]) -> Option<usize> {
    let mut result = 0;
    while line.get(result).map(|c| SPACES.contains(c)) == Some(true) {
        result += 1
    }
    Some(result).filter(|&x| x != 0)
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
