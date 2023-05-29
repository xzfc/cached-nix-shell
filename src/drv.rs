use nom::branch::alt;
use nom::bytes::complete::{escaped_transform, is_not, tag};
use nom::character::complete::char;
use nom::combinator::{eof, opt, value};
use nom::multi::separated_list0;
use nom::sequence::{delimited, preceded, tuple};
use nom::{AsChar, IResult, InputIter, Slice};
use std::ffi::{OsStr, OsString};
use std::fmt::Debug;
use std::fs::read;
use std::ops::RangeFrom;
use std::os::unix::prelude::OsStringExt;
use std::path::Path;

#[derive(Debug)]
#[allow(dead_code)]
struct Derivation {
    outputs: Vec<(OsString, OsString, OsString, OsString)>,
    input_drvs: Vec<(OsString, Vec<OsString>)>,
    input_srcs: Vec<OsString>,
    platform: OsString,
    builder: OsString,
    args: Vec<OsString>,
    env: Vec<(OsString, OsString)>,
}

/// Check if .drv file is present, and all of its inputs (both .drv and their
/// outputs) are present.
pub fn derivation_is_ok<P: AsRef<OsStr>>(path: P) -> Result<(), String> {
    // nix-shell doesn't create an output for the shell derivation, so we
    // check it's dependencies instead.
    for (drv, outputs) in load_derive(&path)?.input_drvs {
        let parsed_drv = load_derive(&drv)?;
        for out_name in outputs {
            let name = &parsed_drv
                .outputs
                .iter()
                .find(|(name, _, _, _)| name == &out_name)
                .ok_or_else(|| {
                    format!(
                        "{}: output {:?} not found",
                        drv.to_string_lossy(),
                        out_name
                    )
                })?
                .1;
            if !Path::new(&name).exists() {
                return Err(format!("{}: not found", name.to_string_lossy()));
            }
        }
    }
    Ok(())
}

fn load_derive<P: AsRef<OsStr>>(path: P) -> Result<Derivation, String> {
    let data = read(path.as_ref())
        .map_err(|e| format!("{}: !{}", path.as_ref().to_string_lossy(), e))?;
    parse_derive(&data).map(|a| a.1).map_err(|_| {
        format!("{}: failed to parse", path.as_ref().to_string_lossy())
    })
}

fn parse_derive(input: &[u8]) -> IResult<&[u8], Derivation> {
    let (input, values) = delimited(
        tag("Derive"),
        tuple((
            preceded(char('('), parse_list(parse_output)),
            preceded(char(','), parse_list(parse_input_drv)),
            preceded(char(','), parse_list(parse_string)),
            preceded(char(','), parse_string),
            preceded(char(','), parse_string),
            preceded(char(','), parse_list(parse_string)),
            preceded(char(','), parse_list(parse_env)),
        )),
        preceded(char(')'), eof),
    )(input)?;

    let result = Derivation {
        outputs: values.0,
        input_drvs: values.1,
        input_srcs: values.2,
        platform: values.3,
        builder: values.4,
        args: values.5,
        env: values.6,
    };
    Ok((input, result))
}

fn parse_output(
    input: &[u8],
) -> IResult<&[u8], (OsString, OsString, OsString, OsString)> {
    tuple((
        preceded(char('('), parse_string),
        preceded(char(','), parse_string),
        preceded(char(','), parse_string),
        delimited(char(','), parse_string, char(')')),
    ))(input)
}

fn parse_input_drv(input: &[u8]) -> IResult<&[u8], (OsString, Vec<OsString>)> {
    tuple((
        preceded(char('('), parse_string),
        delimited(char(','), parse_list(parse_string), char(')')),
    ))(input)
}

fn parse_env(input: &[u8]) -> IResult<&[u8], (OsString, OsString)> {
    tuple((
        preceded(char('('), parse_string),
        delimited(char(','), parse_string, char(')')),
    ))(input)
}

fn parse_list<I, O, E, F>(f: F) -> impl FnMut(I) -> IResult<I, Vec<O>, E>
where
    I: Clone + nom::InputLength + Slice<RangeFrom<usize>> + InputIter,
    <I as InputIter>::Item: AsChar,
    F: nom::Parser<I, O, E>,
    E: nom::error::ParseError<I>,
{
    delimited(char('['), separated_list0(char(','), f), char(']'))
}

fn parse_string(input: &[u8]) -> IResult<&[u8], OsString> {
    let (input, parsed) = delimited(
        char('\"'),
        opt(escaped_transform(
            is_not("\\\""),
            '\\',
            alt((
                value(b"\\" as &'static [u8], char('\\')),
                value(b"\"" as &'static [u8], char('"')),
                value(b"\n" as &'static [u8], char('n')),
            )),
        )),
        char('\"'),
    )(input)?;
    Ok((input, OsString::from_vec(parsed.unwrap_or_default())))
}
