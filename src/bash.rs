pub fn is_literal_bash_string(command: &[u8]) -> bool {
    let mut previous = None;
    for &c in command {
        if b"\t\n !\"$&'()*,;<>?[\\]^`{|}".contains(&c) {
            return false;
        }
        if previous == None && b"#-~".contains(&c) {
            // Special case: `-` isn't a part of bash syntax, but it is treated
            // as an argument of `exec`.
            return false;
        }
        if (previous == Some(b':') || previous == Some(b'=')) && c == b'~' {
            return false;
        }
        previous = Some(c);
    }
    true
}
