use std::collections::HashSet;
use std::ffi::OsStr;
use std::fs::read;
use std::os::unix::ffi::OsStrExt as _;
use std::path::Path;

/// Check if .drv file is present, and all of its inputs (both .drv and their
/// outputs) are present.
pub fn derivation_is_ok<P: AsRef<OsStr>>(path: P) -> Result<(), String> {
    // nix-shell doesn't create an output for the shell derivation, so we
    // check it's dependencies instead.

    let mut files_to_check = HashSet::new();

    parse_derive(
        Path::new(path.as_ref()),
        |_, _| (),
        |drv_path, outputs| {
            parse_derive(
                Path::new(OsStr::from_bytes(drv_path)),
                |name, path| {
                    if outputs.contains(&name) {
                        files_to_check.insert(path.to_vec());
                    }
                },
                |_, _| Ok(()),
            )
        },
    )?;

    for fname in files_to_check.into_iter() {
        let path = Path::new(OsStr::from_bytes(&fname));
        if !path.exists() {
            return Err(format!("{}: not found", path.display()));
        }
    }

    Ok(())
}

/// Load .drv file and call handlers on parsed data.
/// For the reference, the .drv file format is:
/// ```text
/// Derive(
///     // Outputs, passed to `handle_output`.
///     // E.g. `("out", "/nix/store/…-stdenv-linux", "", "")`.
///     [(name, path, hash_algo, hash), …],
///
///     // Inputs, passed to `handle_input`.
///     // E.g. `("/nix/store/…-glibc-2.40-36.drv", ["bin", "dev", "out"])`.
///     [(path, [name, …]), …],
///
///     // The rest is ignored by this function.
///     [input_src, …],
///     platform,         // Platform, e.g. "x86_64-linux".
///     builder,          // Builder path, e.g. "/nix/store/…/bin/bash".
///     [args, …],        // Builder arguments.
///     [(key, value), …] // Environment.
/// )
/// ```
fn parse_derive<T>(
    path: &Path,
    mut handle_output: impl FnMut(&[u8], &[u8]),
    mut handle_input: impl FnMut(&[u8], &[&[u8]]) -> Result<T, String>,
) -> Result<(), String> {
    let input =
        read(path).map_err(|e| format!("{}: !{}", path.display(), e))?;
    let input = input.as_slice();

    let input = tag(input, "Derive(")?;
    let input =
        parse_list(input, |input| parse_output(input, &mut handle_output))?;
    let input = tag(input, ",")?;
    let input =
        parse_list(input, |input| handle_input_drv(input, &mut handle_input))?;
    let input = tag(input, ",")?;
    let _ = input; // skip rest
    Ok(())
}

fn parse_output<'a>(
    input: &'a [u8],
    mut handle_output: impl FnMut(&'a [u8], &'a [u8]),
) -> Result<&'a [u8], String> {
    let input = tag(input, "(")?;
    let (input, name) = parse_string(input)?;
    let input = tag(input, ",")?;
    let (input, path) = parse_string(input)?;
    let input = tag(input, ",")?;
    let (input, _) = parse_string(input)?;
    let input = tag(input, ",")?;
    let (input, _) = parse_string(input)?;
    let input = tag(input, ")")?;

    handle_output(name, path);
    Ok(input)
}

fn handle_input_drv<'a, T>(
    input: &'a [u8],
    mut handle_input: impl FnMut(&'a [u8], &[&'a [u8]]) -> Result<T, String>,
) -> Result<&[u8], String> {
    let input = tag(input, "(")?;
    let (input, drv_path) = parse_string(input)?;
    let input = tag(input, ",")?;
    let mut outputs = Vec::new();
    let input = parse_list(input, |input| {
        let (input, output) = parse_string(input)?;
        outputs.push(output);
        Ok(input)
    })?;
    let input = tag(input, ")")?;
    handle_input(drv_path, &outputs)?;
    Ok(input)
}

fn tag<'a>(input: &'a [u8], tag: &str) -> Result<&'a [u8], String> {
    if input.starts_with(tag.as_bytes()) {
        Ok(&input[tag.len()..])
    } else {
        Err(format!("parse error: expected {tag:?}"))
    }
}

fn parse_list<'a>(
    mut input: &'a [u8],
    mut f: impl FnMut(&'a [u8]) -> Result<&'a [u8], String>,
) -> Result<&'a [u8], String> {
    input = tag(input, "[")?;
    loop {
        input = f(input)?;
        match input.first() {
            Some(b',') => input = &input[1..],
            Some(b']') => return Ok(&input[1..]),
            _ => return Err("parse error: expected , or ]".to_string()),
        }
    }
}

fn parse_string(input: &[u8]) -> Result<(&[u8], &[u8]), String> {
    let input = tag(input, "\"")?;
    let mut backslash = false;
    for (n, &c) in input.iter().enumerate() {
        if backslash {
            backslash = false;
        } else {
            match c {
                b'\\' => backslash = true,
                b'"' => return Ok((&input[n + 1..], &input[..n])),
                _ => (),
            }
        }
    }
    Err("parse error: expected \"".to_string())
}
