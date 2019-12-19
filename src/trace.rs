use crypto::digest::Digest;
use crypto::md5::Md5;
use itertools::Itertools;
use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs::File;
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
            .map(|x| Vec::from(x))
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
            OsStr::new("???") // TODO
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
