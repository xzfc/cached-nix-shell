use itertools::Itertools;
use std::collections::btree_map::Entry;
use std::collections::BTreeMap;
use std::ffi::{OsStr, OsString};
use std::fs::{read, read_dir, read_link, symlink_metadata};
use std::io::ErrorKind;
use std::os::unix::ffi::OsStrExt;
use ufcs::Pipe;

pub struct Trace(Vec<(Vec<u8>, Vec<u8>)>);

impl Trace {
    /// Load trace from a vector of bytes, as returned by `trace-nix.so`.
    /// Sort and deduplicate entries. Remove entries inside temporary
    /// directories created by fetchTarball.
    pub fn load_raw(vec: Vec<u8>) -> Trace {
        let mut result = BTreeMap::<Vec<u8>, Vec<u8>>::new();
        let mut inbetween = BTreeMap::<Vec<u8>, Vec<(Vec<u8>, Vec<u8>)>>::new();

        // In between `tTMPDIR\0+\0` and `tTMPDIR\0-\0`, ignore all entries
        // starting with `TMPDIR/`, including `TMPDIR` itself, if `TMPDIR` is
        // no longer exists. This corresponds to the temporary directory created
        // by fetchTarball.

        'outer: for (key, value) in vec
            .split(|&b| b == 0)
            .filter(|&fname| !fname.is_empty()) // last entry has trailing NUL
            .map(Vec::from)
            .tuples::<(_, _)>()
        {
            let fname = OsStr::from_bytes(&key[1..]);

            if key.iter().next() == Some(&b't') {
                match value.as_slice() {
                    b"+" => {
                        // Handle mkdir
                        if symlink_metadata(fname).is_ok() {
                            // Unlikely: temporary directory still exists
                            continue;
                        }
                        match inbetween.entry(key[1..].to_vec()) {
                            Entry::Vacant(entry) => {
                                // Likely.
                                entry.insert(Vec::new());
                            }
                            Entry::Occupied(mut entry) => {
                                // Unlikely: the directory with the same
                                // name was created twice.
                                for (k, v) in entry.get_mut().drain(..) {
                                    result.insert(k, v);
                                }
                                *entry.get_mut() = Vec::new();
                            }
                        }
                    }
                    b"-" => {
                        // Handle unlinkat
                        eprintln!(
                            "cached-nix-shell: happily ignoring {}",
                            fname.to_string_lossy()
                        );
                        for (k, _) in
                            inbetween.remove(&key[1..]).unwrap_or_default()
                        {
                            eprintln!(
                                "cached-nix-shell:   {}",
                                OsStr::from_bytes(&k[1..]).to_string_lossy()
                            );
                        }
                        // inbetween.remove(&key[1..]);
                    }
                    _ => panic!("Unexpected"),
                }
            } else {
                for (k, v) in inbetween.iter_mut() {
                    if k == &key[1..]
                        || key[1..].starts_with(k)
                            && key.get(k.len() + 1) == Some(&b'/')
                    {
                        v.push((key.clone(), value.clone()));
                        continue 'outer;
                    }
                }
                result.insert(key, value);
            }
        }

        for (_, v) in inbetween {
            for (k, v) in v {
                result.insert(k, v);
            }
        }

        Trace(result.into_iter().collect())
    }

    /// Load trace from a vector of bytes, as stored in the cache.
    pub fn load_sorted(vec: Vec<u8>) -> Trace {
        vec.split(|&b| b == 0)
            .filter(|&fname| !fname.is_empty()) // last entry has trailing NUL
            .map(Vec::from)
            .tuples::<(_, _)>()
            .collect::<Vec<_>>()
            .pipe(Trace)
    }

    pub fn serialize(&self) -> Vec<u8> {
        let mut result = Vec::<u8>::new();
        for (a, b) in &self.0 {
            result.push(0);
            result.extend(a);
            result.push(0);
            result.extend(b);
        }
        result
    }

    /// Return true if trace doesn't match (i.e. some file is changed)
    pub fn check_for_changes(&self) -> bool {
        for (k, v) in &self.0 {
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
