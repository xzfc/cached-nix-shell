use itertools::Itertools;
use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs::{read, read_dir, read_link, symlink_metadata};
use std::io::ErrorKind;
use std::os::unix::ffi::OsStrExt;
use log::error;

/// Output of trace-nix.so, sorted and deduplicated.
pub struct Trace {
    items: BTreeMap<Vec<u8>, Vec<u8>>,
}

impl Trace {
    pub fn load(vec: Vec<u8>) -> Trace {
        let items = vec
            .split(|&b| b == 0)
            .filter(|&fname| !fname.is_empty()) // last entry has trailing NUL
            .map(Vec::from)
            .tuples::<(_, _)>()
            .collect::<BTreeMap<Vec<u8>, Vec<u8>>>();
        Trace { items }
    }

    pub fn serialize(&self) -> Vec<u8> {
        let mut result = Vec::<u8>::new();
        for (a, b) in &self.items {
            result.push(0);
            result.extend(a);
            result.push(0);
            result.extend(b);
        }
        result
    }

    /// Return true if trace doesn't match (i.e. some file is changed)
    pub fn check_for_changes(&self) -> bool {
        for (k, v) in &self.items {
            if check_item_updated(k, v) {
                return true;
            }
        }
        false
    }
}

fn check_item_updated(k: &[u8], v: &[u8]) -> bool {
    let tmp: OsString;
    let fname = OsStr::from_bytes(&k[1..]);
    let res = match k.iter().next() {
        Some(b's') => match symlink_metadata(fname) {
            Err(_) => OsStr::new("-"),
            Ok(md) => {
                if md.file_type().is_symlink() {
                    let mut l = OsString::from("l");
                    l.push(read_link(fname).expect("Can't read link"));
                    tmp = l;
                    tmp.as_os_str()
                } else if md.file_type().is_dir() {
                    OsStr::new("d")
                } else {
                    OsStr::new("+")
                }
            }
        },
        Some(b'f') => match read(fname) {
            Ok(data) => {
                tmp = OsString::from(
                    &blake3::hash(&data).to_hex().as_str()[..32],
                );
                tmp.as_os_str()
            }
            Err(ref e) if e.kind() == ErrorKind::NotFound => OsStr::new("-"),
            Err(_) => OsStr::new("e"),
        },
        Some(b'd') => {
            tmp = hash_dir(fname);
            tmp.as_os_str()
        }
        _ => panic!("Unexpected"),
    };

    if res.as_bytes() != v {
        error!(
            "{:?}: expected {:?}, got {:?}",
            fname,
            OsStr::from_bytes(v),
            res
        );
        return true;
    }
    false
}

fn hash_dir(fname: &OsStr) -> OsString {
    let entries = match read_dir(fname) {
        Ok(x) => x,
        Err(_) => return OsString::from("-"),
    };

    let mut hasher = blake3::Hasher::new();
    entries
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let typ = match entry.file_type() {
                Ok(typ) => {
                    if typ.is_symlink() {
                        b'l'
                    } else if typ.is_file() {
                        b'f'
                    } else if typ.is_dir() {
                        b'd'
                    } else {
                        b'u'
                    }
                }
                Err(_) => return None,
            };
            Some([entry.file_name().as_bytes(), &[b'=', typ, 0]].concat())
        })
        .sorted()
        .for_each(|entry| {
            hasher.update(&entry);
        });
    OsString::from(&hasher.finalize().to_hex().as_str()[..32])
}
