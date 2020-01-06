use crypto::digest::Digest;
use crypto::md5::Md5;
use itertools::Itertools;
use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs::{read_dir, File};
use std::io::Read;
use std::os::unix::ffi::OsStrExt;

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
        for (a, b) in self.items.iter() {
            result.push(0);
            result.extend(a);
            result.push(0);
            result.extend(b);
        }
        result
    }

    /// Return true if trace doesn't match (i.e. some file is changed)
    pub fn check_for_changes(&self) -> bool {
        for (k, v) in self.items.iter() {
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
        Some(b's') => match nix::sys::stat::lstat(fname) {
            Ok(_) => match nix::fcntl::readlink(fname) {
                Ok(x) => {
                    tmp = x;
                    tmp.as_os_str()
                }
                Err(_) => OsStr::new("+"),
            },
            Err(_) => OsStr::new("-"),
        },
        Some(b'f') => match File::open(fname) {
            Ok(mut file) => {
                let mut data = Vec::new();
                file.read_to_end(&mut data).expect("Can't read file");

                let mut digest = Md5::new();
                digest.input(&data);

                tmp = OsString::from(digest.result_str());
                tmp.as_os_str()
            }
            Err(_) => OsStr::new("-"),
        },
        Some(b'd') => {
            tmp = hash_dir(fname);
            tmp.as_os_str()
        }
        _ => panic!("Unexpected"),
    };

    if res.as_bytes() != v {
        eprintln!(
            "cached-nix-shell: {:?}: expected {:?}, got {:?}",
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

    let mut digest = Md5::new();
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
        .for_each(|entry| digest.input(&entry));
    OsString::from(digest.result_str())
}
