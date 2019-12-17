{ lib, buildRustCrate, buildRustCrateHelpers }:
with buildRustCrateHelpers;
let inherit (lib.lists) fold;
    inherit (lib.attrsets) recursiveUpdate;
in
rec {

# aho-corasick-0.7.6

  crates.aho_corasick."0.7.6" = deps: { features?(features_.aho_corasick."0.7.6" deps {}) }: buildRustCrate {
    crateName = "aho-corasick";
    version = "0.7.6";
    description = "Fast multiple substring searching.";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" ];
    sha256 = "1srdggg7iawz7rfyb79qfnz6vmzkgl6g6gabyd9ad6pbx7zzj8gz";
    libName = "aho_corasick";
    dependencies = mapFeatures features ([
      (crates."memchr"."${deps."aho_corasick"."0.7.6"."memchr"}" deps)
    ]);
    features = mkFeatures (features."aho_corasick"."0.7.6" or {});
  };
  features_.aho_corasick."0.7.6" = deps: f: updateFeatures f (rec {
    aho_corasick = fold recursiveUpdate {} [
      { "0.7.6"."std" =
        (f.aho_corasick."0.7.6"."std" or false) ||
        (f.aho_corasick."0.7.6".default or false) ||
        (aho_corasick."0.7.6"."default" or false); }
      { "0.7.6".default = (f.aho_corasick."0.7.6".default or true); }
    ];
    memchr = fold recursiveUpdate {} [
      { "${deps.aho_corasick."0.7.6".memchr}"."use_std" =
        (f.memchr."${deps.aho_corasick."0.7.6".memchr}"."use_std" or false) ||
        (aho_corasick."0.7.6"."std" or false) ||
        (f."aho_corasick"."0.7.6"."std" or false); }
      { "${deps.aho_corasick."0.7.6".memchr}".default = (f.memchr."${deps.aho_corasick."0.7.6".memchr}".default or false); }
    ];
  }) [
    (features_.memchr."${deps."aho_corasick"."0.7.6"."memchr"}" deps)
  ];


# end
# bitflags-1.2.1

  crates.bitflags."1.2.1" = deps: { features?(features_.bitflags."1.2.1" deps {}) }: buildRustCrate {
    crateName = "bitflags";
    version = "1.2.1";
    description = "A macro to generate structures which behave like bitflags.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0b77awhpn7yaqjjibm69ginfn996azx5vkzfjj39g3wbsqs7mkxg";
    build = "build.rs";
    features = mkFeatures (features."bitflags"."1.2.1" or {});
  };
  features_.bitflags."1.2.1" = deps: f: updateFeatures f (rec {
    bitflags."1.2.1".default = (f.bitflags."1.2.1".default or true);
  }) [];


# end
# c2-chacha-0.2.3

  crates.c2_chacha."0.2.3" = deps: { features?(features_.c2_chacha."0.2.3" deps {}) }: buildRustCrate {
    crateName = "c2-chacha";
    version = "0.2.3";
    description = "The ChaCha family of stream ciphers";
    authors = [ "The CryptoCorrosion Contributors" ];
    edition = "2018";
    sha256 = "04vh0cc9g94cj6cq96sfv3lks7rx486jdn43rmqcvb2syh4y9dqj";
    dependencies = mapFeatures features ([
      (crates."ppv_lite86"."${deps."c2_chacha"."0.2.3"."ppv_lite86"}" deps)
    ]);
    features = mkFeatures (features."c2_chacha"."0.2.3" or {});
  };
  features_.c2_chacha."0.2.3" = deps: f: updateFeatures f (rec {
    c2_chacha = fold recursiveUpdate {} [
      { "0.2.3"."byteorder" =
        (f.c2_chacha."0.2.3"."byteorder" or false) ||
        (f.c2_chacha."0.2.3".rustcrypto_api or false) ||
        (c2_chacha."0.2.3"."rustcrypto_api" or false); }
      { "0.2.3"."rustcrypto_api" =
        (f.c2_chacha."0.2.3"."rustcrypto_api" or false) ||
        (f.c2_chacha."0.2.3".default or false) ||
        (c2_chacha."0.2.3"."default" or false); }
      { "0.2.3"."simd" =
        (f.c2_chacha."0.2.3"."simd" or false) ||
        (f.c2_chacha."0.2.3".default or false) ||
        (c2_chacha."0.2.3"."default" or false); }
      { "0.2.3"."std" =
        (f.c2_chacha."0.2.3"."std" or false) ||
        (f.c2_chacha."0.2.3".default or false) ||
        (c2_chacha."0.2.3"."default" or false); }
      { "0.2.3"."stream-cipher" =
        (f.c2_chacha."0.2.3"."stream-cipher" or false) ||
        (f.c2_chacha."0.2.3".rustcrypto_api or false) ||
        (c2_chacha."0.2.3"."rustcrypto_api" or false); }
      { "0.2.3".default = (f.c2_chacha."0.2.3".default or true); }
    ];
    ppv_lite86 = fold recursiveUpdate {} [
      { "${deps.c2_chacha."0.2.3".ppv_lite86}"."simd" =
        (f.ppv_lite86."${deps.c2_chacha."0.2.3".ppv_lite86}"."simd" or false) ||
        (c2_chacha."0.2.3"."simd" or false) ||
        (f."c2_chacha"."0.2.3"."simd" or false); }
      { "${deps.c2_chacha."0.2.3".ppv_lite86}"."std" =
        (f.ppv_lite86."${deps.c2_chacha."0.2.3".ppv_lite86}"."std" or false) ||
        (c2_chacha."0.2.3"."std" or false) ||
        (f."c2_chacha"."0.2.3"."std" or false); }
      { "${deps.c2_chacha."0.2.3".ppv_lite86}".default = (f.ppv_lite86."${deps.c2_chacha."0.2.3".ppv_lite86}".default or false); }
    ];
  }) [
    (features_.ppv_lite86."${deps."c2_chacha"."0.2.3"."ppv_lite86"}" deps)
  ];


# end
# cc-1.0.48

  crates.cc."1.0.48" = deps: { features?(features_.cc."1.0.48" deps {}) }: buildRustCrate {
    crateName = "cc";
    version = "1.0.48";
    description = "A build-time dependency for Cargo build scripts to assist in invoking the native\nC compiler to compile native C code into a static archive to be linked into Rust\ncode.\n";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    edition = "2018";
    sha256 = "1i8h3f949i0ymlyj8nn80v8q5h4cqz6m953vks1lhii9gz0gq329";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."cc"."1.0.48" or {});
  };
  features_.cc."1.0.48" = deps: f: updateFeatures f (rec {
    cc = fold recursiveUpdate {} [
      { "1.0.48"."jobserver" =
        (f.cc."1.0.48"."jobserver" or false) ||
        (f.cc."1.0.48".parallel or false) ||
        (cc."1.0.48"."parallel" or false); }
      { "1.0.48"."num_cpus" =
        (f.cc."1.0.48"."num_cpus" or false) ||
        (f.cc."1.0.48".parallel or false) ||
        (cc."1.0.48"."parallel" or false); }
      { "1.0.48".default = (f.cc."1.0.48".default or true); }
    ];
  }) [];


# end
# cfg-if-0.1.10

  crates.cfg_if."0.1.10" = deps: { features?(features_.cfg_if."0.1.10" deps {}) }: buildRustCrate {
    crateName = "cfg-if";
    version = "0.1.10";
    description = "A macro to ergonomically define an item depending on a large number of #[cfg]\nparameters. Structured like an if-else chain, the first matching branch is the\nitem that gets emitted.\n";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    edition = "2018";
    sha256 = "0x52qzpbyl2f2jqs7kkqzgfki2cpq99gpfjjigdp8pwwfqk01007";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."cfg_if"."0.1.10" or {});
  };
  features_.cfg_if."0.1.10" = deps: f: updateFeatures f (rec {
    cfg_if = fold recursiveUpdate {} [
      { "0.1.10"."compiler_builtins" =
        (f.cfg_if."0.1.10"."compiler_builtins" or false) ||
        (f.cfg_if."0.1.10".rustc-dep-of-std or false) ||
        (cfg_if."0.1.10"."rustc-dep-of-std" or false); }
      { "0.1.10"."core" =
        (f.cfg_if."0.1.10"."core" or false) ||
        (f.cfg_if."0.1.10".rustc-dep-of-std or false) ||
        (cfg_if."0.1.10"."rustc-dep-of-std" or false); }
      { "0.1.10".default = (f.cfg_if."0.1.10".default or true); }
    ];
  }) [];


# end
# either-1.5.3

  crates.either."1.5.3" = deps: { features?(features_.either."1.5.3" deps {}) }: buildRustCrate {
    crateName = "either";
    version = "1.5.3";
    description = "The enum `Either` with variants `Left` and `Right` is a general purpose sum type with two cases.\n";
    authors = [ "bluss" ];
    sha256 = "040fgh0jahqra9ascwb986zgll1ss88ky9bfvn0zfay42zsyz83n";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."either"."1.5.3" or {});
  };
  features_.either."1.5.3" = deps: f: updateFeatures f (rec {
    either = fold recursiveUpdate {} [
      { "1.5.3"."use_std" =
        (f.either."1.5.3"."use_std" or false) ||
        (f.either."1.5.3".default or false) ||
        (either."1.5.3"."default" or false); }
      { "1.5.3".default = (f.either."1.5.3".default or true); }
    ];
  }) [];


# end
# fuchsia-cprng-0.1.1

  crates.fuchsia_cprng."0.1.1" = deps: { features?(features_.fuchsia_cprng."0.1.1" deps {}) }: buildRustCrate {
    crateName = "fuchsia-cprng";
    version = "0.1.1";
    description = "Rust crate for the Fuchsia cryptographically secure pseudorandom number generator";
    authors = [ "Erick Tryzelaar <etryzelaar@google.com>" ];
    edition = "2018";
    sha256 = "07apwv9dj716yjlcj29p94vkqn5zmfh7hlrqvrjx3wzshphc95h9";
  };
  features_.fuchsia_cprng."0.1.1" = deps: f: updateFeatures f (rec {
    fuchsia_cprng."0.1.1".default = (f.fuchsia_cprng."0.1.1".default or true);
  }) [];


# end
# gcc-0.3.55

  crates.gcc."0.3.55" = deps: { features?(features_.gcc."0.3.55" deps {}) }: buildRustCrate {
    crateName = "gcc";
    version = "0.3.55";
    description = "**Deprecated** crate, renamed to `cc`\n\nA build-time dependency for Cargo build scripts to assist in invoking the native\nC compiler to compile native C code into a static archive to be linked into Rust\ncode.\n";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    sha256 = "18qxv3hjdhp7pfcvbm2hvyicpgmk7xw8aii1l7fla8cxxbcrg2nz";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."gcc"."0.3.55" or {});
  };
  features_.gcc."0.3.55" = deps: f: updateFeatures f (rec {
    gcc = fold recursiveUpdate {} [
      { "0.3.55"."rayon" =
        (f.gcc."0.3.55"."rayon" or false) ||
        (f.gcc."0.3.55".parallel or false) ||
        (gcc."0.3.55"."parallel" or false); }
      { "0.3.55".default = (f.gcc."0.3.55".default or true); }
    ];
  }) [];


# end
# getrandom-0.1.13

  crates.getrandom."0.1.13" = deps: { features?(features_.getrandom."0.1.13" deps {}) }: buildRustCrate {
    crateName = "getrandom";
    version = "0.1.13";
    description = "A small cross-platform library for retrieving random data from system source";
    authors = [ "The Rand Project Developers" ];
    edition = "2018";
    sha256 = "0js1vkdrqy94vfn39p8i93zcr1r4mjbvy78dbrbx7s8rd6xl33md";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."getrandom"."0.1.13"."cfg_if"}" deps)
    ])
      ++ (if kernel == "wasi" then mapFeatures features ([
      (crates."wasi"."${deps."getrandom"."0.1.13"."wasi"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."getrandom"."0.1.13"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "wasm32-unknown-unknown" then mapFeatures features ([
]) else []);
    features = mkFeatures (features."getrandom"."0.1.13" or {});
  };
  features_.getrandom."0.1.13" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.getrandom."0.1.13".cfg_if}".default = true;
    getrandom = fold recursiveUpdate {} [
      { "0.1.13"."compiler_builtins" =
        (f.getrandom."0.1.13"."compiler_builtins" or false) ||
        (f.getrandom."0.1.13".rustc-dep-of-std or false) ||
        (getrandom."0.1.13"."rustc-dep-of-std" or false); }
      { "0.1.13"."core" =
        (f.getrandom."0.1.13"."core" or false) ||
        (f.getrandom."0.1.13".rustc-dep-of-std or false) ||
        (getrandom."0.1.13"."rustc-dep-of-std" or false); }
      { "0.1.13"."wasm-bindgen" =
        (f.getrandom."0.1.13"."wasm-bindgen" or false) ||
        (f.getrandom."0.1.13".test-in-browser or false) ||
        (getrandom."0.1.13"."test-in-browser" or false); }
      { "0.1.13".default = (f.getrandom."0.1.13".default or true); }
    ];
    libc."${deps.getrandom."0.1.13".libc}".default = (f.libc."${deps.getrandom."0.1.13".libc}".default or false);
    wasi."${deps.getrandom."0.1.13".wasi}".default = true;
  }) [
    (features_.cfg_if."${deps."getrandom"."0.1.13"."cfg_if"}" deps)
    (features_.wasi."${deps."getrandom"."0.1.13"."wasi"}" deps)
    (features_.libc."${deps."getrandom"."0.1.13"."libc"}" deps)
  ];


# end
# itertools-0.8.2

  crates.itertools."0.8.2" = deps: { features?(features_.itertools."0.8.2" deps {}) }: buildRustCrate {
    crateName = "itertools";
    version = "0.8.2";
    description = "Extra iterator adaptors, iterator methods, free functions, and macros.";
    authors = [ "bluss" ];
    sha256 = "08ibirc0yiijx66aqszx4psz08zkn4fp4627dym94xcrib12na9r";
    dependencies = mapFeatures features ([
      (crates."either"."${deps."itertools"."0.8.2"."either"}" deps)
    ]);
    features = mkFeatures (features."itertools"."0.8.2" or {});
  };
  features_.itertools."0.8.2" = deps: f: updateFeatures f (rec {
    either."${deps.itertools."0.8.2".either}".default = (f.either."${deps.itertools."0.8.2".either}".default or false);
    itertools = fold recursiveUpdate {} [
      { "0.8.2"."use_std" =
        (f.itertools."0.8.2"."use_std" or false) ||
        (f.itertools."0.8.2".default or false) ||
        (itertools."0.8.2"."default" or false); }
      { "0.8.2".default = (f.itertools."0.8.2".default or true); }
    ];
  }) [
    (features_.either."${deps."itertools"."0.8.2"."either"}" deps)
  ];


# end
# itoa-0.4.4

  crates.itoa."0.4.4" = deps: { features?(features_.itoa."0.4.4" deps {}) }: buildRustCrate {
    crateName = "itoa";
    version = "0.4.4";
    description = "Fast functions for printing integer primitives to an io::Write";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "1fqc34xzzl2spfdawxd9awhzl0fwf1y6y4i94l8bq8rfrzd90awl";
    features = mkFeatures (features."itoa"."0.4.4" or {});
  };
  features_.itoa."0.4.4" = deps: f: updateFeatures f (rec {
    itoa = fold recursiveUpdate {} [
      { "0.4.4"."std" =
        (f.itoa."0.4.4"."std" or false) ||
        (f.itoa."0.4.4".default or false) ||
        (itoa."0.4.4"."default" or false); }
      { "0.4.4".default = (f.itoa."0.4.4".default or true); }
    ];
  }) [];


# end
# lazy_static-1.4.0

  crates.lazy_static."1.4.0" = deps: { features?(features_.lazy_static."1.4.0" deps {}) }: buildRustCrate {
    crateName = "lazy_static";
    version = "1.4.0";
    description = "A macro for declaring lazily evaluated statics in Rust.";
    authors = [ "Marvin Löbel <loebel.marvin@gmail.com>" ];
    sha256 = "13h6sdghdcy7vcqsm2gasfw3qg7ssa0fl3sw7lq6pdkbk52wbyfr";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."lazy_static"."1.4.0" or {});
  };
  features_.lazy_static."1.4.0" = deps: f: updateFeatures f (rec {
    lazy_static = fold recursiveUpdate {} [
      { "1.4.0"."spin" =
        (f.lazy_static."1.4.0"."spin" or false) ||
        (f.lazy_static."1.4.0".spin_no_std or false) ||
        (lazy_static."1.4.0"."spin_no_std" or false); }
      { "1.4.0".default = (f.lazy_static."1.4.0".default or true); }
    ];
  }) [];


# end
# libc-0.2.66

  crates.libc."0.2.66" = deps: { features?(features_.libc."0.2.66" deps {}) }: buildRustCrate {
    crateName = "libc";
    version = "0.2.66";
    description = "Raw FFI bindings to platform libraries like libc.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0wz5fdpjpj8qp7wx7gq9rqckd2bdv7hcm5631hq03amxy5ikhi3l";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."libc"."0.2.66" or {});
  };
  features_.libc."0.2.66" = deps: f: updateFeatures f (rec {
    libc = fold recursiveUpdate {} [
      { "0.2.66"."align" =
        (f.libc."0.2.66"."align" or false) ||
        (f.libc."0.2.66".rustc-dep-of-std or false) ||
        (libc."0.2.66"."rustc-dep-of-std" or false); }
      { "0.2.66"."rustc-std-workspace-core" =
        (f.libc."0.2.66"."rustc-std-workspace-core" or false) ||
        (f.libc."0.2.66".rustc-dep-of-std or false) ||
        (libc."0.2.66"."rustc-dep-of-std" or false); }
      { "0.2.66"."std" =
        (f.libc."0.2.66"."std" or false) ||
        (f.libc."0.2.66".default or false) ||
        (libc."0.2.66"."default" or false) ||
        (f.libc."0.2.66".use_std or false) ||
        (libc."0.2.66"."use_std" or false); }
      { "0.2.66".default = (f.libc."0.2.66".default or true); }
    ];
  }) [];


# end
# memchr-2.2.1

  crates.memchr."2.2.1" = deps: { features?(features_.memchr."2.2.1" deps {}) }: buildRustCrate {
    crateName = "memchr";
    version = "2.2.1";
    description = "Safe interface to memchr.";
    authors = [ "Andrew Gallant <jamslam@gmail.com>" "bluss" ];
    sha256 = "1mj5z8lhz6jbapslpq8a39pwcsl1p0jmgp7wgcj7nv4pcqhya7a0";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."memchr"."2.2.1" or {});
  };
  features_.memchr."2.2.1" = deps: f: updateFeatures f (rec {
    memchr = fold recursiveUpdate {} [
      { "2.2.1"."use_std" =
        (f.memchr."2.2.1"."use_std" or false) ||
        (f.memchr."2.2.1".default or false) ||
        (memchr."2.2.1"."default" or false); }
      { "2.2.1".default = (f.memchr."2.2.1".default or true); }
    ];
  }) [];


# end
# nix-0.16.0

  crates.nix."0.16.0" = deps: { features?(features_.nix."0.16.0" deps {}) }: buildRustCrate {
    crateName = "nix";
    version = "0.16.0";
    description = "Rust friendly bindings to *nix APIs";
    authors = [ "The nix-rust Project Developers" ];
    sha256 = "1qp1in8b6r7r91l821qaxjanm4r14823i4zr8bfkbacyvp1ldzpg";
    dependencies = mapFeatures features ([
      (crates."bitflags"."${deps."nix"."0.16.0"."bitflags"}" deps)
      (crates."cfg_if"."${deps."nix"."0.16.0"."cfg_if"}" deps)
      (crates."libc"."${deps."nix"."0.16.0"."libc"}" deps)
      (crates."void"."${deps."nix"."0.16.0"."void"}" deps)
    ])
      ++ (if kernel == "android" || kernel == "linux" then mapFeatures features ([
]) else [])
      ++ (if kernel == "dragonfly" then mapFeatures features ([
]) else [])
      ++ (if kernel == "freebsd" then mapFeatures features ([
]) else []);
  };
  features_.nix."0.16.0" = deps: f: updateFeatures f (rec {
    bitflags."${deps.nix."0.16.0".bitflags}".default = true;
    cfg_if."${deps.nix."0.16.0".cfg_if}".default = true;
    libc = fold recursiveUpdate {} [
      { "${deps.nix."0.16.0".libc}"."extra_traits" = true; }
      { "${deps.nix."0.16.0".libc}".default = true; }
    ];
    nix."0.16.0".default = (f.nix."0.16.0".default or true);
    void."${deps.nix."0.16.0".void}".default = true;
  }) [
    (features_.bitflags."${deps."nix"."0.16.0"."bitflags"}" deps)
    (features_.cfg_if."${deps."nix"."0.16.0"."cfg_if"}" deps)
    (features_.libc."${deps."nix"."0.16.0"."libc"}" deps)
    (features_.void."${deps."nix"."0.16.0"."void"}" deps)
  ];


# end
# ppv-lite86-0.2.6

  crates.ppv_lite86."0.2.6" = deps: { features?(features_.ppv_lite86."0.2.6" deps {}) }: buildRustCrate {
    crateName = "ppv-lite86";
    version = "0.2.6";
    description = "Implementation of the crypto-simd API for x86";
    authors = [ "The CryptoCorrosion Contributors" ];
    edition = "2018";
    sha256 = "1mlbp0713frbyvcbjmc5vl062b0vr58agkv3ar2qqi5plgy9b7ib";
    features = mkFeatures (features."ppv_lite86"."0.2.6" or {});
  };
  features_.ppv_lite86."0.2.6" = deps: f: updateFeatures f (rec {
    ppv_lite86 = fold recursiveUpdate {} [
      { "0.2.6"."simd" =
        (f.ppv_lite86."0.2.6"."simd" or false) ||
        (f.ppv_lite86."0.2.6".default or false) ||
        (ppv_lite86."0.2.6"."default" or false); }
      { "0.2.6"."std" =
        (f.ppv_lite86."0.2.6"."std" or false) ||
        (f.ppv_lite86."0.2.6".default or false) ||
        (ppv_lite86."0.2.6"."default" or false); }
      { "0.2.6".default = (f.ppv_lite86."0.2.6".default or true); }
    ];
  }) [];


# end
# rand-0.3.23

  crates.rand."0.3.23" = deps: { features?(features_.rand."0.3.23" deps {}) }: buildRustCrate {
    crateName = "rand";
    version = "0.3.23";
    description = "Random number generators and other randomness functionality.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "118rairvv46npqqx7hmkf97kkimjrry9z31z4inxcv2vn0nj1s2g";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."rand"."0.3.23"."libc"}" deps)
      (crates."rand"."${deps."rand"."0.3.23"."rand"}" deps)
    ]);
    features = mkFeatures (features."rand"."0.3.23" or {});
  };
  features_.rand."0.3.23" = deps: f: updateFeatures f (rec {
    libc."${deps.rand."0.3.23".libc}".default = true;
    rand = fold recursiveUpdate {} [
      { "${deps.rand."0.3.23".rand}".default = true; }
      { "0.3.23"."i128_support" =
        (f.rand."0.3.23"."i128_support" or false) ||
        (f.rand."0.3.23".nightly or false) ||
        (rand."0.3.23"."nightly" or false); }
      { "0.3.23".default = (f.rand."0.3.23".default or true); }
    ];
  }) [
    (features_.libc."${deps."rand"."0.3.23"."libc"}" deps)
    (features_.rand."${deps."rand"."0.3.23"."rand"}" deps)
  ];


# end
# rand-0.4.6

  crates.rand."0.4.6" = deps: { features?(features_.rand."0.4.6" deps {}) }: buildRustCrate {
    crateName = "rand";
    version = "0.4.6";
    description = "Random number generators and other randomness functionality.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0c3rmg5q7d6qdi7cbmg5py9alm70wd3xsg0mmcawrnl35qv37zfs";
    dependencies = (if abi == "sgx" then mapFeatures features ([
      (crates."rand_core"."${deps."rand"."0.4.6"."rand_core"}" deps)
      (crates."rdrand"."${deps."rand"."0.4.6"."rdrand"}" deps)
    ]) else [])
      ++ (if kernel == "fuchsia" then mapFeatures features ([
      (crates."fuchsia_cprng"."${deps."rand"."0.4.6"."fuchsia_cprng"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
    ]
      ++ (if features.rand."0.4.6".libc or false then [ (crates.libc."${deps."rand"."0.4.6".libc}" deps) ] else [])) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."rand"."0.4.6"."winapi"}" deps)
    ]) else []);
    features = mkFeatures (features."rand"."0.4.6" or {});
  };
  features_.rand."0.4.6" = deps: f: updateFeatures f (rec {
    fuchsia_cprng."${deps.rand."0.4.6".fuchsia_cprng}".default = true;
    libc."${deps.rand."0.4.6".libc}".default = true;
    rand = fold recursiveUpdate {} [
      { "0.4.6"."i128_support" =
        (f.rand."0.4.6"."i128_support" or false) ||
        (f.rand."0.4.6".nightly or false) ||
        (rand."0.4.6"."nightly" or false); }
      { "0.4.6"."libc" =
        (f.rand."0.4.6"."libc" or false) ||
        (f.rand."0.4.6".std or false) ||
        (rand."0.4.6"."std" or false); }
      { "0.4.6"."std" =
        (f.rand."0.4.6"."std" or false) ||
        (f.rand."0.4.6".default or false) ||
        (rand."0.4.6"."default" or false); }
      { "0.4.6".default = (f.rand."0.4.6".default or true); }
    ];
    rand_core."${deps.rand."0.4.6".rand_core}".default = (f.rand_core."${deps.rand."0.4.6".rand_core}".default or false);
    rdrand."${deps.rand."0.4.6".rdrand}".default = true;
    winapi = fold recursiveUpdate {} [
      { "${deps.rand."0.4.6".winapi}"."minwindef" = true; }
      { "${deps.rand."0.4.6".winapi}"."ntsecapi" = true; }
      { "${deps.rand."0.4.6".winapi}"."profileapi" = true; }
      { "${deps.rand."0.4.6".winapi}"."winnt" = true; }
      { "${deps.rand."0.4.6".winapi}".default = true; }
    ];
  }) [
    (features_.rand_core."${deps."rand"."0.4.6"."rand_core"}" deps)
    (features_.rdrand."${deps."rand"."0.4.6"."rdrand"}" deps)
    (features_.fuchsia_cprng."${deps."rand"."0.4.6"."fuchsia_cprng"}" deps)
    (features_.libc."${deps."rand"."0.4.6"."libc"}" deps)
    (features_.winapi."${deps."rand"."0.4.6"."winapi"}" deps)
  ];


# end
# rand-0.7.2

  crates.rand."0.7.2" = deps: { features?(features_.rand."0.7.2" deps {}) }: buildRustCrate {
    crateName = "rand";
    version = "0.7.2";
    description = "Random number generators and other randomness functionality.\n";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    edition = "2018";
    sha256 = "1f53047g63b9kyyx1k8wgwzspk4n96w2n2h1a9848ggl9y9h0ik6";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand"."0.7.2"."rand_core"}" deps)
    ])
      ++ (if !(kernel == "emscripten") then mapFeatures features ([
      (crates."rand_chacha"."${deps."rand"."0.7.2"."rand_chacha"}" deps)
    ]) else [])
      ++ (if kernel == "emscripten" then mapFeatures features ([
      (crates."rand_hc"."${deps."rand"."0.7.2"."rand_hc"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."rand"."0.7.2"."libc"}" deps)
    ]) else []);
    features = mkFeatures (features."rand"."0.7.2" or {});
  };
  features_.rand."0.7.2" = deps: f: updateFeatures f (rec {
    libc."${deps.rand."0.7.2".libc}".default = (f.libc."${deps.rand."0.7.2".libc}".default or false);
    rand = fold recursiveUpdate {} [
      { "0.7.2"."alloc" =
        (f.rand."0.7.2"."alloc" or false) ||
        (f.rand."0.7.2".std or false) ||
        (rand."0.7.2"."std" or false); }
      { "0.7.2"."getrandom" =
        (f.rand."0.7.2"."getrandom" or false) ||
        (f.rand."0.7.2".std or false) ||
        (rand."0.7.2"."std" or false); }
      { "0.7.2"."getrandom_package" =
        (f.rand."0.7.2"."getrandom_package" or false) ||
        (f.rand."0.7.2".getrandom or false) ||
        (rand."0.7.2"."getrandom" or false); }
      { "0.7.2"."packed_simd" =
        (f.rand."0.7.2"."packed_simd" or false) ||
        (f.rand."0.7.2".simd_support or false) ||
        (rand."0.7.2"."simd_support" or false); }
      { "0.7.2"."rand_pcg" =
        (f.rand."0.7.2"."rand_pcg" or false) ||
        (f.rand."0.7.2".small_rng or false) ||
        (rand."0.7.2"."small_rng" or false); }
      { "0.7.2"."simd_support" =
        (f.rand."0.7.2"."simd_support" or false) ||
        (f.rand."0.7.2".nightly or false) ||
        (rand."0.7.2"."nightly" or false); }
      { "0.7.2"."std" =
        (f.rand."0.7.2"."std" or false) ||
        (f.rand."0.7.2".default or false) ||
        (rand."0.7.2"."default" or false); }
      { "0.7.2".default = (f.rand."0.7.2".default or true); }
    ];
    rand_chacha."${deps.rand."0.7.2".rand_chacha}".default = (f.rand_chacha."${deps.rand."0.7.2".rand_chacha}".default or false);
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand."0.7.2".rand_core}"."alloc" =
        (f.rand_core."${deps.rand."0.7.2".rand_core}"."alloc" or false) ||
        (rand."0.7.2"."alloc" or false) ||
        (f."rand"."0.7.2"."alloc" or false); }
      { "${deps.rand."0.7.2".rand_core}"."getrandom" =
        (f.rand_core."${deps.rand."0.7.2".rand_core}"."getrandom" or false) ||
        (rand."0.7.2"."getrandom" or false) ||
        (f."rand"."0.7.2"."getrandom" or false); }
      { "${deps.rand."0.7.2".rand_core}"."std" =
        (f.rand_core."${deps.rand."0.7.2".rand_core}"."std" or false) ||
        (rand."0.7.2"."std" or false) ||
        (f."rand"."0.7.2"."std" or false); }
      { "${deps.rand."0.7.2".rand_core}".default = true; }
    ];
    rand_hc."${deps.rand."0.7.2".rand_hc}".default = true;
  }) [
    (features_.rand_core."${deps."rand"."0.7.2"."rand_core"}" deps)
    (features_.rand_chacha."${deps."rand"."0.7.2"."rand_chacha"}" deps)
    (features_.rand_hc."${deps."rand"."0.7.2"."rand_hc"}" deps)
    (features_.libc."${deps."rand"."0.7.2"."libc"}" deps)
  ];


# end
# rand_chacha-0.2.1

  crates.rand_chacha."0.2.1" = deps: { features?(features_.rand_chacha."0.2.1" deps {}) }: buildRustCrate {
    crateName = "rand_chacha";
    version = "0.2.1";
    description = "ChaCha random number generator\n";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" "The CryptoCorrosion Contributors" ];
    edition = "2018";
    sha256 = "0zpp3wmxhhmripb6bywhzhx5rfwl4dfbny85hpalwdj0sncv0p0k";
    dependencies = mapFeatures features ([
      (crates."c2_chacha"."${deps."rand_chacha"."0.2.1"."c2_chacha"}" deps)
      (crates."rand_core"."${deps."rand_chacha"."0.2.1"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rand_chacha"."0.2.1" or {});
  };
  features_.rand_chacha."0.2.1" = deps: f: updateFeatures f (rec {
    c2_chacha = fold recursiveUpdate {} [
      { "${deps.rand_chacha."0.2.1".c2_chacha}"."simd" = true; }
      { "${deps.rand_chacha."0.2.1".c2_chacha}"."std" =
        (f.c2_chacha."${deps.rand_chacha."0.2.1".c2_chacha}"."std" or false) ||
        (rand_chacha."0.2.1"."std" or false) ||
        (f."rand_chacha"."0.2.1"."std" or false); }
      { "${deps.rand_chacha."0.2.1".c2_chacha}".default = (f.c2_chacha."${deps.rand_chacha."0.2.1".c2_chacha}".default or false); }
    ];
    rand_chacha = fold recursiveUpdate {} [
      { "0.2.1"."simd" =
        (f.rand_chacha."0.2.1"."simd" or false) ||
        (f.rand_chacha."0.2.1".default or false) ||
        (rand_chacha."0.2.1"."default" or false); }
      { "0.2.1"."std" =
        (f.rand_chacha."0.2.1"."std" or false) ||
        (f.rand_chacha."0.2.1".default or false) ||
        (rand_chacha."0.2.1"."default" or false); }
      { "0.2.1".default = (f.rand_chacha."0.2.1".default or true); }
    ];
    rand_core."${deps.rand_chacha."0.2.1".rand_core}".default = true;
  }) [
    (features_.c2_chacha."${deps."rand_chacha"."0.2.1"."c2_chacha"}" deps)
    (features_.rand_core."${deps."rand_chacha"."0.2.1"."rand_core"}" deps)
  ];


# end
# rand_core-0.3.1

  crates.rand_core."0.3.1" = deps: { features?(features_.rand_core."0.3.1" deps {}) }: buildRustCrate {
    crateName = "rand_core";
    version = "0.3.1";
    description = "Core random number generator traits and tools for implementation.\n";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "0q0ssgpj9x5a6fda83nhmfydy7a6c0wvxm0jhncsmjx8qp8gw91m";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_core"."0.3.1"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rand_core"."0.3.1" or {});
  };
  features_.rand_core."0.3.1" = deps: f: updateFeatures f (rec {
    rand_core = fold recursiveUpdate {} [
      { "${deps.rand_core."0.3.1".rand_core}"."alloc" =
        (f.rand_core."${deps.rand_core."0.3.1".rand_core}"."alloc" or false) ||
        (rand_core."0.3.1"."alloc" or false) ||
        (f."rand_core"."0.3.1"."alloc" or false); }
      { "${deps.rand_core."0.3.1".rand_core}"."serde1" =
        (f.rand_core."${deps.rand_core."0.3.1".rand_core}"."serde1" or false) ||
        (rand_core."0.3.1"."serde1" or false) ||
        (f."rand_core"."0.3.1"."serde1" or false); }
      { "${deps.rand_core."0.3.1".rand_core}"."std" =
        (f.rand_core."${deps.rand_core."0.3.1".rand_core}"."std" or false) ||
        (rand_core."0.3.1"."std" or false) ||
        (f."rand_core"."0.3.1"."std" or false); }
      { "${deps.rand_core."0.3.1".rand_core}".default = true; }
      { "0.3.1"."std" =
        (f.rand_core."0.3.1"."std" or false) ||
        (f.rand_core."0.3.1".default or false) ||
        (rand_core."0.3.1"."default" or false); }
      { "0.3.1".default = (f.rand_core."0.3.1".default or true); }
    ];
  }) [
    (features_.rand_core."${deps."rand_core"."0.3.1"."rand_core"}" deps)
  ];


# end
# rand_core-0.4.2

  crates.rand_core."0.4.2" = deps: { features?(features_.rand_core."0.4.2" deps {}) }: buildRustCrate {
    crateName = "rand_core";
    version = "0.4.2";
    description = "Core random number generator traits and tools for implementation.\n";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    sha256 = "18zpzwn4bl7lp9f36iacy8mvdnfrhfmzsl35gmln98dcindff2ly";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."rand_core"."0.4.2" or {});
  };
  features_.rand_core."0.4.2" = deps: f: updateFeatures f (rec {
    rand_core = fold recursiveUpdate {} [
      { "0.4.2"."alloc" =
        (f.rand_core."0.4.2"."alloc" or false) ||
        (f.rand_core."0.4.2".std or false) ||
        (rand_core."0.4.2"."std" or false); }
      { "0.4.2"."serde" =
        (f.rand_core."0.4.2"."serde" or false) ||
        (f.rand_core."0.4.2".serde1 or false) ||
        (rand_core."0.4.2"."serde1" or false); }
      { "0.4.2"."serde_derive" =
        (f.rand_core."0.4.2"."serde_derive" or false) ||
        (f.rand_core."0.4.2".serde1 or false) ||
        (rand_core."0.4.2"."serde1" or false); }
      { "0.4.2".default = (f.rand_core."0.4.2".default or true); }
    ];
  }) [];


# end
# rand_core-0.5.1

  crates.rand_core."0.5.1" = deps: { features?(features_.rand_core."0.5.1" deps {}) }: buildRustCrate {
    crateName = "rand_core";
    version = "0.5.1";
    description = "Core random number generator traits and tools for implementation.\n";
    authors = [ "The Rand Project Developers" "The Rust Project Developers" ];
    edition = "2018";
    sha256 = "19qfnh77bzz0x2gfsk91h0gygy0z1s5l3yyc2j91gmprq60d6s3r";
    dependencies = mapFeatures features ([
    ]
      ++ (if features.rand_core."0.5.1".getrandom or false then [ (crates.getrandom."${deps."rand_core"."0.5.1".getrandom}" deps) ] else []));
    features = mkFeatures (features."rand_core"."0.5.1" or {});
  };
  features_.rand_core."0.5.1" = deps: f: updateFeatures f (rec {
    getrandom = fold recursiveUpdate {} [
      { "${deps.rand_core."0.5.1".getrandom}"."std" =
        (f.getrandom."${deps.rand_core."0.5.1".getrandom}"."std" or false) ||
        (rand_core."0.5.1"."std" or false) ||
        (f."rand_core"."0.5.1"."std" or false); }
      { "${deps.rand_core."0.5.1".getrandom}".default = true; }
    ];
    rand_core = fold recursiveUpdate {} [
      { "0.5.1"."alloc" =
        (f.rand_core."0.5.1"."alloc" or false) ||
        (f.rand_core."0.5.1".std or false) ||
        (rand_core."0.5.1"."std" or false); }
      { "0.5.1"."getrandom" =
        (f.rand_core."0.5.1"."getrandom" or false) ||
        (f.rand_core."0.5.1".std or false) ||
        (rand_core."0.5.1"."std" or false); }
      { "0.5.1"."serde" =
        (f.rand_core."0.5.1"."serde" or false) ||
        (f.rand_core."0.5.1".serde1 or false) ||
        (rand_core."0.5.1"."serde1" or false); }
      { "0.5.1".default = (f.rand_core."0.5.1".default or true); }
    ];
  }) [
    (features_.getrandom."${deps."rand_core"."0.5.1"."getrandom"}" deps)
  ];


# end
# rand_hc-0.2.0

  crates.rand_hc."0.2.0" = deps: { features?(features_.rand_hc."0.2.0" deps {}) }: buildRustCrate {
    crateName = "rand_hc";
    version = "0.2.0";
    description = "HC128 random number generator\n";
    authors = [ "The Rand Project Developers" ];
    edition = "2018";
    sha256 = "0592q9kqcna9aiyzy6vp3fadxkkbpfkmi2cnkv48zhybr0v2yf01";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rand_hc"."0.2.0"."rand_core"}" deps)
    ]);
  };
  features_.rand_hc."0.2.0" = deps: f: updateFeatures f (rec {
    rand_core."${deps.rand_hc."0.2.0".rand_core}".default = true;
    rand_hc."0.2.0".default = (f.rand_hc."0.2.0".default or true);
  }) [
    (features_.rand_core."${deps."rand_hc"."0.2.0"."rand_core"}" deps)
  ];


# end
# rdrand-0.4.0

  crates.rdrand."0.4.0" = deps: { features?(features_.rdrand."0.4.0" deps {}) }: buildRustCrate {
    crateName = "rdrand";
    version = "0.4.0";
    description = "An implementation of random number generator based on rdrand and rdseed instructions";
    authors = [ "Simonas Kazlauskas <rdrand@kazlauskas.me>" ];
    sha256 = "15hrcasn0v876wpkwab1dwbk9kvqwrb3iv4y4dibb6yxnfvzwajk";
    dependencies = mapFeatures features ([
      (crates."rand_core"."${deps."rdrand"."0.4.0"."rand_core"}" deps)
    ]);
    features = mkFeatures (features."rdrand"."0.4.0" or {});
  };
  features_.rdrand."0.4.0" = deps: f: updateFeatures f (rec {
    rand_core."${deps.rdrand."0.4.0".rand_core}".default = (f.rand_core."${deps.rdrand."0.4.0".rand_core}".default or false);
    rdrand = fold recursiveUpdate {} [
      { "0.4.0"."std" =
        (f.rdrand."0.4.0"."std" or false) ||
        (f.rdrand."0.4.0".default or false) ||
        (rdrand."0.4.0"."default" or false); }
      { "0.4.0".default = (f.rdrand."0.4.0".default or true); }
    ];
  }) [
    (features_.rand_core."${deps."rdrand"."0.4.0"."rand_core"}" deps)
  ];


# end
# redox_syscall-0.1.56

  crates.redox_syscall."0.1.56" = deps: { features?(features_.redox_syscall."0.1.56" deps {}) }: buildRustCrate {
    crateName = "redox_syscall";
    version = "0.1.56";
    description = "A Rust library to access raw Redox system calls";
    authors = [ "Jeremy Soller <jackpot51@gmail.com>" ];
    sha256 = "0jcp8nd947zcy938bz09pzlmi3vyxfdzg92pjxdvvk0699vwcc26";
    libName = "syscall";
  };
  features_.redox_syscall."0.1.56" = deps: f: updateFeatures f (rec {
    redox_syscall."0.1.56".default = (f.redox_syscall."0.1.56".default or true);
  }) [];


# end
# regex-1.3.1

  crates.regex."1.3.1" = deps: { features?(features_.regex."1.3.1" deps {}) }: buildRustCrate {
    crateName = "regex";
    version = "1.3.1";
    description = "An implementation of regular expressions for Rust. This implementation uses\nfinite automata and guarantees linear time matching on all inputs.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0508b01q7iwky5gzp1cc3lpz6al1qam8skgcvkfgxr67nikiz7jn";
    dependencies = mapFeatures features ([
      (crates."regex_syntax"."${deps."regex"."1.3.1"."regex_syntax"}" deps)
    ]
      ++ (if features.regex."1.3.1".aho-corasick or false then [ (crates.aho_corasick."${deps."regex"."1.3.1".aho_corasick}" deps) ] else [])
      ++ (if features.regex."1.3.1".memchr or false then [ (crates.memchr."${deps."regex"."1.3.1".memchr}" deps) ] else [])
      ++ (if features.regex."1.3.1".thread_local or false then [ (crates.thread_local."${deps."regex"."1.3.1".thread_local}" deps) ] else []));
    features = mkFeatures (features."regex"."1.3.1" or {});
  };
  features_.regex."1.3.1" = deps: f: updateFeatures f (rec {
    aho_corasick."${deps.regex."1.3.1".aho_corasick}".default = true;
    memchr."${deps.regex."1.3.1".memchr}".default = true;
    regex = fold recursiveUpdate {} [
      { "1.3.1"."aho-corasick" =
        (f.regex."1.3.1"."aho-corasick" or false) ||
        (f.regex."1.3.1".perf-literal or false) ||
        (regex."1.3.1"."perf-literal" or false); }
      { "1.3.1"."memchr" =
        (f.regex."1.3.1"."memchr" or false) ||
        (f.regex."1.3.1".perf-literal or false) ||
        (regex."1.3.1"."perf-literal" or false); }
      { "1.3.1"."pattern" =
        (f.regex."1.3.1"."pattern" or false) ||
        (f.regex."1.3.1".unstable or false) ||
        (regex."1.3.1"."unstable" or false); }
      { "1.3.1"."perf" =
        (f.regex."1.3.1"."perf" or false) ||
        (f.regex."1.3.1".default or false) ||
        (regex."1.3.1"."default" or false); }
      { "1.3.1"."perf-cache" =
        (f.regex."1.3.1"."perf-cache" or false) ||
        (f.regex."1.3.1".perf or false) ||
        (regex."1.3.1"."perf" or false); }
      { "1.3.1"."perf-dfa" =
        (f.regex."1.3.1"."perf-dfa" or false) ||
        (f.regex."1.3.1".perf or false) ||
        (regex."1.3.1"."perf" or false); }
      { "1.3.1"."perf-inline" =
        (f.regex."1.3.1"."perf-inline" or false) ||
        (f.regex."1.3.1".perf or false) ||
        (regex."1.3.1"."perf" or false); }
      { "1.3.1"."perf-literal" =
        (f.regex."1.3.1"."perf-literal" or false) ||
        (f.regex."1.3.1".perf or false) ||
        (regex."1.3.1"."perf" or false); }
      { "1.3.1"."std" =
        (f.regex."1.3.1"."std" or false) ||
        (f.regex."1.3.1".default or false) ||
        (regex."1.3.1"."default" or false) ||
        (f.regex."1.3.1".use_std or false) ||
        (regex."1.3.1"."use_std" or false); }
      { "1.3.1"."thread_local" =
        (f.regex."1.3.1"."thread_local" or false) ||
        (f.regex."1.3.1".perf-cache or false) ||
        (regex."1.3.1"."perf-cache" or false); }
      { "1.3.1"."unicode" =
        (f.regex."1.3.1"."unicode" or false) ||
        (f.regex."1.3.1".default or false) ||
        (regex."1.3.1"."default" or false); }
      { "1.3.1"."unicode-age" =
        (f.regex."1.3.1"."unicode-age" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-bool" =
        (f.regex."1.3.1"."unicode-bool" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-case" =
        (f.regex."1.3.1"."unicode-case" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-gencat" =
        (f.regex."1.3.1"."unicode-gencat" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-perl" =
        (f.regex."1.3.1"."unicode-perl" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-script" =
        (f.regex."1.3.1"."unicode-script" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1"."unicode-segment" =
        (f.regex."1.3.1"."unicode-segment" or false) ||
        (f.regex."1.3.1".unicode or false) ||
        (regex."1.3.1"."unicode" or false); }
      { "1.3.1".default = (f.regex."1.3.1".default or true); }
    ];
    regex_syntax = fold recursiveUpdate {} [
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-age" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-age" or false) ||
        (regex."1.3.1"."unicode-age" or false) ||
        (f."regex"."1.3.1"."unicode-age" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-bool" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-bool" or false) ||
        (regex."1.3.1"."unicode-bool" or false) ||
        (f."regex"."1.3.1"."unicode-bool" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-case" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-case" or false) ||
        (regex."1.3.1"."unicode-case" or false) ||
        (f."regex"."1.3.1"."unicode-case" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-gencat" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-gencat" or false) ||
        (regex."1.3.1"."unicode-gencat" or false) ||
        (f."regex"."1.3.1"."unicode-gencat" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-perl" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-perl" or false) ||
        (regex."1.3.1"."unicode-perl" or false) ||
        (f."regex"."1.3.1"."unicode-perl" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-script" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-script" or false) ||
        (regex."1.3.1"."unicode-script" or false) ||
        (f."regex"."1.3.1"."unicode-script" or false); }
      { "${deps.regex."1.3.1".regex_syntax}"."unicode-segment" =
        (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}"."unicode-segment" or false) ||
        (regex."1.3.1"."unicode-segment" or false) ||
        (f."regex"."1.3.1"."unicode-segment" or false); }
      { "${deps.regex."1.3.1".regex_syntax}".default = (f.regex_syntax."${deps.regex."1.3.1".regex_syntax}".default or false); }
    ];
    thread_local."${deps.regex."1.3.1".thread_local}".default = true;
  }) [
    (features_.aho_corasick."${deps."regex"."1.3.1"."aho_corasick"}" deps)
    (features_.memchr."${deps."regex"."1.3.1"."memchr"}" deps)
    (features_.regex_syntax."${deps."regex"."1.3.1"."regex_syntax"}" deps)
    (features_.thread_local."${deps."regex"."1.3.1"."thread_local"}" deps)
  ];


# end
# regex-syntax-0.6.12

  crates.regex_syntax."0.6.12" = deps: { features?(features_.regex_syntax."0.6.12" deps {}) }: buildRustCrate {
    crateName = "regex-syntax";
    version = "0.6.12";
    description = "A regular expression parser.";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1lqhddhwzpgq8zfkxhm241n7g4m3yc11fb4098dkgawbxvybr53v";
    features = mkFeatures (features."regex_syntax"."0.6.12" or {});
  };
  features_.regex_syntax."0.6.12" = deps: f: updateFeatures f (rec {
    regex_syntax = fold recursiveUpdate {} [
      { "0.6.12"."unicode" =
        (f.regex_syntax."0.6.12"."unicode" or false) ||
        (f.regex_syntax."0.6.12".default or false) ||
        (regex_syntax."0.6.12"."default" or false); }
      { "0.6.12"."unicode-age" =
        (f.regex_syntax."0.6.12"."unicode-age" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-bool" =
        (f.regex_syntax."0.6.12"."unicode-bool" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-case" =
        (f.regex_syntax."0.6.12"."unicode-case" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-gencat" =
        (f.regex_syntax."0.6.12"."unicode-gencat" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-perl" =
        (f.regex_syntax."0.6.12"."unicode-perl" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-script" =
        (f.regex_syntax."0.6.12"."unicode-script" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12"."unicode-segment" =
        (f.regex_syntax."0.6.12"."unicode-segment" or false) ||
        (f.regex_syntax."0.6.12".unicode or false) ||
        (regex_syntax."0.6.12"."unicode" or false); }
      { "0.6.12".default = (f.regex_syntax."0.6.12".default or true); }
    ];
  }) [];


# end
# remove_dir_all-0.5.2

  crates.remove_dir_all."0.5.2" = deps: { features?(features_.remove_dir_all."0.5.2" deps {}) }: buildRustCrate {
    crateName = "remove_dir_all";
    version = "0.5.2";
    description = "A safe, reliable implementation of remove_dir_all for Windows";
    authors = [ "Aaronepower <theaaronepower@gmail.com>" ];
    sha256 = "04sxg2ppvxiljc2i13bwvpbi540rf9d2a89cq0wmqf9pjvr3a1wm";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."remove_dir_all"."0.5.2"."winapi"}" deps)
    ]) else []);
  };
  features_.remove_dir_all."0.5.2" = deps: f: updateFeatures f (rec {
    remove_dir_all."0.5.2".default = (f.remove_dir_all."0.5.2".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.remove_dir_all."0.5.2".winapi}"."errhandlingapi" = true; }
      { "${deps.remove_dir_all."0.5.2".winapi}"."fileapi" = true; }
      { "${deps.remove_dir_all."0.5.2".winapi}"."std" = true; }
      { "${deps.remove_dir_all."0.5.2".winapi}"."winbase" = true; }
      { "${deps.remove_dir_all."0.5.2".winapi}"."winerror" = true; }
      { "${deps.remove_dir_all."0.5.2".winapi}".default = true; }
    ];
  }) [
    (features_.winapi."${deps."remove_dir_all"."0.5.2"."winapi"}" deps)
  ];


# end
# rust-crypto-0.2.36

  crates.rust_crypto."0.2.36" = deps: { features?(features_.rust_crypto."0.2.36" deps {}) }: buildRustCrate {
    crateName = "rust-crypto";
    version = "0.2.36";
    description = "A (mostly) pure-Rust implementation of various common cryptographic algorithms.";
    authors = [ "The Rust-Crypto Project Developers" ];
    sha256 = "1hm79xjmkyl20bx4b8ns77xbrm8wqklhqnci54n93zr6wiq3ddgi";
    libName = "crypto";
    build = "build.rs";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."rust_crypto"."0.2.36"."libc"}" deps)
      (crates."rand"."${deps."rust_crypto"."0.2.36"."rand"}" deps)
      (crates."rustc_serialize"."${deps."rust_crypto"."0.2.36"."rustc_serialize"}" deps)
      (crates."time"."${deps."rust_crypto"."0.2.36"."time"}" deps)
    ]);

    buildDependencies = mapFeatures features ([
      (crates."gcc"."${deps."rust_crypto"."0.2.36"."gcc"}" deps)
    ]);
    features = mkFeatures (features."rust_crypto"."0.2.36" or {});
  };
  features_.rust_crypto."0.2.36" = deps: f: updateFeatures f (rec {
    gcc."${deps.rust_crypto."0.2.36".gcc}".default = true;
    libc."${deps.rust_crypto."0.2.36".libc}".default = true;
    rand."${deps.rust_crypto."0.2.36".rand}".default = true;
    rust_crypto."0.2.36".default = (f.rust_crypto."0.2.36".default or true);
    rustc_serialize."${deps.rust_crypto."0.2.36".rustc_serialize}".default = true;
    time."${deps.rust_crypto."0.2.36".time}".default = true;
  }) [
    (features_.libc."${deps."rust_crypto"."0.2.36"."libc"}" deps)
    (features_.rand."${deps."rust_crypto"."0.2.36"."rand"}" deps)
    (features_.rustc_serialize."${deps."rust_crypto"."0.2.36"."rustc_serialize"}" deps)
    (features_.time."${deps."rust_crypto"."0.2.36"."time"}" deps)
    (features_.gcc."${deps."rust_crypto"."0.2.36"."gcc"}" deps)
  ];


# end
# rustc-serialize-0.3.24

  crates.rustc_serialize."0.3.24" = deps: { features?(features_.rustc_serialize."0.3.24" deps {}) }: buildRustCrate {
    crateName = "rustc-serialize";
    version = "0.3.24";
    description = "Generic serialization/deserialization support corresponding to the\n`derive(RustcEncodable, RustcDecodable)` mode in the compiler. Also includes\nsupport for hex, base64, and json encoding and decoding.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "0rfk6p66mqkd3g36l0ddlv2rvnp1mp3lrq5frq9zz5cbnz5pmmxn";
  };
  features_.rustc_serialize."0.3.24" = deps: f: updateFeatures f (rec {
    rustc_serialize."0.3.24".default = (f.rustc_serialize."0.3.24".default or true);
  }) [];


# end
# ryu-1.0.2

  crates.ryu."1.0.2" = deps: { features?(features_.ryu."1.0.2" deps {}) }: buildRustCrate {
    crateName = "ryu";
    version = "1.0.2";
    description = "Fast floating point to string conversion";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "04pxfhps9ix078qyml7hifjdmy4bg1n047ki0wx6i1007z85wjp1";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."ryu"."1.0.2" or {});
  };
  features_.ryu."1.0.2" = deps: f: updateFeatures f (rec {
    ryu."1.0.2".default = (f.ryu."1.0.2".default or true);
  }) [];


# end
# serde-1.0.104

  crates.serde."1.0.104" = deps: { features?(features_.serde."1.0.104" deps {}) }: buildRustCrate {
    crateName = "serde";
    version = "1.0.104";
    description = "A generic serialization/deserialization framework";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0dsn86dafbfm5hhngzay7s4pmb4hskpjjyw2f9l7wm9s28gs5ckf";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."serde"."1.0.104" or {});
  };
  features_.serde."1.0.104" = deps: f: updateFeatures f (rec {
    serde = fold recursiveUpdate {} [
      { "1.0.104"."serde_derive" =
        (f.serde."1.0.104"."serde_derive" or false) ||
        (f.serde."1.0.104".derive or false) ||
        (serde."1.0.104"."derive" or false); }
      { "1.0.104"."std" =
        (f.serde."1.0.104"."std" or false) ||
        (f.serde."1.0.104".default or false) ||
        (serde."1.0.104"."default" or false); }
      { "1.0.104".default = (f.serde."1.0.104".default or true); }
    ];
  }) [];


# end
# serde_json-1.0.44

  crates.serde_json."1.0.44" = deps: { features?(features_.serde_json."1.0.44" deps {}) }: buildRustCrate {
    crateName = "serde_json";
    version = "1.0.44";
    description = "A JSON serialization file format";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "04i068sibjfwg67nvg2yddj0iwznwk9cpcx6rxd1q5gqc76mvl7b";
    dependencies = mapFeatures features ([
      (crates."itoa"."${deps."serde_json"."1.0.44"."itoa"}" deps)
      (crates."ryu"."${deps."serde_json"."1.0.44"."ryu"}" deps)
      (crates."serde"."${deps."serde_json"."1.0.44"."serde"}" deps)
    ]);
    features = mkFeatures (features."serde_json"."1.0.44" or {});
  };
  features_.serde_json."1.0.44" = deps: f: updateFeatures f (rec {
    itoa."${deps.serde_json."1.0.44".itoa}".default = true;
    ryu."${deps.serde_json."1.0.44".ryu}".default = true;
    serde."${deps.serde_json."1.0.44".serde}".default = true;
    serde_json = fold recursiveUpdate {} [
      { "1.0.44"."indexmap" =
        (f.serde_json."1.0.44"."indexmap" or false) ||
        (f.serde_json."1.0.44".preserve_order or false) ||
        (serde_json."1.0.44"."preserve_order" or false); }
      { "1.0.44".default = (f.serde_json."1.0.44".default or true); }
    ];
  }) [
    (features_.itoa."${deps."serde_json"."1.0.44"."itoa"}" deps)
    (features_.ryu."${deps."serde_json"."1.0.44"."ryu"}" deps)
    (features_.serde."${deps."serde_json"."1.0.44"."serde"}" deps)
  ];


# end
# shellwords-1.0.0

  crates.shellwords."1.0.0" = deps: { features?(features_.shellwords."1.0.0" deps {}) }: buildRustCrate {
    crateName = "shellwords";
    version = "1.0.0";
    description = "Manipulate strings according to the word parsing rules of the UNIX Bourne shell.";
    authors = [ "Jimmy Cuadra <jimmy@jimmycuadra.com>" ];
    sha256 = "102pql0nyky5dvvcak0skn1yswadsjblq52l3ymjb3n0n32ci2v6";
    dependencies = mapFeatures features ([
      (crates."lazy_static"."${deps."shellwords"."1.0.0"."lazy_static"}" deps)
      (crates."regex"."${deps."shellwords"."1.0.0"."regex"}" deps)
    ]);
  };
  features_.shellwords."1.0.0" = deps: f: updateFeatures f (rec {
    lazy_static."${deps.shellwords."1.0.0".lazy_static}".default = true;
    regex."${deps.shellwords."1.0.0".regex}".default = true;
    shellwords."1.0.0".default = (f.shellwords."1.0.0".default or true);
  }) [
    (features_.lazy_static."${deps."shellwords"."1.0.0"."lazy_static"}" deps)
    (features_.regex."${deps."shellwords"."1.0.0"."regex"}" deps)
  ];


# end
# tempfile-3.1.0

  crates.tempfile."3.1.0" = deps: { features?(features_.tempfile."3.1.0" deps {}) }: buildRustCrate {
    crateName = "tempfile";
    version = "3.1.0";
    description = "A library for managing temporary files and directories.";
    authors = [ "Steven Allen <steven@stebalien.com>" "The Rust Project Developers" "Ashley Mannix <ashleymannix@live.com.au>" "Jason White <jasonaw0@gmail.com>" ];
    edition = "2018";
    sha256 = "1r7ykxw90p5hm1g46i8ia33j5iwl3q252kbb6b074qhdav3sqndk";
    dependencies = mapFeatures features ([
      (crates."cfg_if"."${deps."tempfile"."3.1.0"."cfg_if"}" deps)
      (crates."rand"."${deps."tempfile"."3.1.0"."rand"}" deps)
      (crates."remove_dir_all"."${deps."tempfile"."3.1.0"."remove_dir_all"}" deps)
    ])
      ++ (if kernel == "redox" then mapFeatures features ([
      (crates."redox_syscall"."${deps."tempfile"."3.1.0"."redox_syscall"}" deps)
    ]) else [])
      ++ (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."tempfile"."3.1.0"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."tempfile"."3.1.0"."winapi"}" deps)
    ]) else []);
  };
  features_.tempfile."3.1.0" = deps: f: updateFeatures f (rec {
    cfg_if."${deps.tempfile."3.1.0".cfg_if}".default = true;
    libc."${deps.tempfile."3.1.0".libc}".default = true;
    rand."${deps.tempfile."3.1.0".rand}".default = true;
    redox_syscall."${deps.tempfile."3.1.0".redox_syscall}".default = true;
    remove_dir_all."${deps.tempfile."3.1.0".remove_dir_all}".default = true;
    tempfile."3.1.0".default = (f.tempfile."3.1.0".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.tempfile."3.1.0".winapi}"."fileapi" = true; }
      { "${deps.tempfile."3.1.0".winapi}"."handleapi" = true; }
      { "${deps.tempfile."3.1.0".winapi}"."winbase" = true; }
      { "${deps.tempfile."3.1.0".winapi}".default = true; }
    ];
  }) [
    (features_.cfg_if."${deps."tempfile"."3.1.0"."cfg_if"}" deps)
    (features_.rand."${deps."tempfile"."3.1.0"."rand"}" deps)
    (features_.remove_dir_all."${deps."tempfile"."3.1.0"."remove_dir_all"}" deps)
    (features_.redox_syscall."${deps."tempfile"."3.1.0"."redox_syscall"}" deps)
    (features_.libc."${deps."tempfile"."3.1.0"."libc"}" deps)
    (features_.winapi."${deps."tempfile"."3.1.0"."winapi"}" deps)
  ];


# end
# thread_local-0.3.6

  crates.thread_local."0.3.6" = deps: { features?(features_.thread_local."0.3.6" deps {}) }: buildRustCrate {
    crateName = "thread_local";
    version = "0.3.6";
    description = "Per-object thread-local storage";
    authors = [ "Amanieu d'Antras <amanieu@gmail.com>" ];
    sha256 = "02rksdwjmz2pw9bmgbb4c0bgkbq5z6nvg510sq1s6y2j1gam0c7i";
    dependencies = mapFeatures features ([
      (crates."lazy_static"."${deps."thread_local"."0.3.6"."lazy_static"}" deps)
    ]);
  };
  features_.thread_local."0.3.6" = deps: f: updateFeatures f (rec {
    lazy_static."${deps.thread_local."0.3.6".lazy_static}".default = true;
    thread_local."0.3.6".default = (f.thread_local."0.3.6".default or true);
  }) [
    (features_.lazy_static."${deps."thread_local"."0.3.6"."lazy_static"}" deps)
  ];


# end
# time-0.1.42

  crates.time."0.1.42" = deps: { features?(features_.time."0.1.42" deps {}) }: buildRustCrate {
    crateName = "time";
    version = "0.1.42";
    description = "Utilities for working with time-related functions in Rust.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1ny809kmdjwd4b478ipc33dz7q6nq7rxk766x8cnrg6zygcksmmx";
    dependencies = mapFeatures features ([
      (crates."libc"."${deps."time"."0.1.42"."libc"}" deps)
    ])
      ++ (if kernel == "redox" then mapFeatures features ([
      (crates."redox_syscall"."${deps."time"."0.1.42"."redox_syscall"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."time"."0.1.42"."winapi"}" deps)
    ]) else []);
  };
  features_.time."0.1.42" = deps: f: updateFeatures f (rec {
    libc."${deps.time."0.1.42".libc}".default = true;
    redox_syscall."${deps.time."0.1.42".redox_syscall}".default = true;
    time."0.1.42".default = (f.time."0.1.42".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.time."0.1.42".winapi}"."minwinbase" = true; }
      { "${deps.time."0.1.42".winapi}"."minwindef" = true; }
      { "${deps.time."0.1.42".winapi}"."ntdef" = true; }
      { "${deps.time."0.1.42".winapi}"."profileapi" = true; }
      { "${deps.time."0.1.42".winapi}"."std" = true; }
      { "${deps.time."0.1.42".winapi}"."sysinfoapi" = true; }
      { "${deps.time."0.1.42".winapi}"."timezoneapi" = true; }
      { "${deps.time."0.1.42".winapi}".default = true; }
    ];
  }) [
    (features_.libc."${deps."time"."0.1.42"."libc"}" deps)
    (features_.redox_syscall."${deps."time"."0.1.42"."redox_syscall"}" deps)
    (features_.winapi."${deps."time"."0.1.42"."winapi"}" deps)
  ];


# end
# void-1.0.2

  crates.void."1.0.2" = deps: { features?(features_.void."1.0.2" deps {}) }: buildRustCrate {
    crateName = "void";
    version = "1.0.2";
    description = "The uninhabited void type for use in statically impossible cases.";
    authors = [ "Jonathan Reem <jonathan.reem@gmail.com>" ];
    sha256 = "0h1dm0dx8dhf56a83k68mijyxigqhizpskwxfdrs1drwv2cdclv3";
    features = mkFeatures (features."void"."1.0.2" or {});
  };
  features_.void."1.0.2" = deps: f: updateFeatures f (rec {
    void = fold recursiveUpdate {} [
      { "1.0.2"."std" =
        (f.void."1.0.2"."std" or false) ||
        (f.void."1.0.2".default or false) ||
        (void."1.0.2"."default" or false); }
      { "1.0.2".default = (f.void."1.0.2".default or true); }
    ];
  }) [];


# end
# wasi-0.7.0

  crates.wasi."0.7.0" = deps: { features?(features_.wasi."0.7.0" deps {}) }: buildRustCrate {
    crateName = "wasi";
    version = "0.7.0";
    description = "Experimental WASI API bindings for Rust";
    authors = [ "The Cranelift Project Developers" ];
    edition = "2018";
    sha256 = "1lqknxy8x9mrsy0pna6xlwzypbhli73nbai9gmin5f4z1ghlng25";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."wasi"."0.7.0" or {});
  };
  features_.wasi."0.7.0" = deps: f: updateFeatures f (rec {
    wasi = fold recursiveUpdate {} [
      { "0.7.0"."alloc" =
        (f.wasi."0.7.0"."alloc" or false) ||
        (f.wasi."0.7.0".default or false) ||
        (wasi."0.7.0"."default" or false); }
      { "0.7.0"."compiler_builtins" =
        (f.wasi."0.7.0"."compiler_builtins" or false) ||
        (f.wasi."0.7.0".rustc-dep-of-std or false) ||
        (wasi."0.7.0"."rustc-dep-of-std" or false); }
      { "0.7.0"."core" =
        (f.wasi."0.7.0"."core" or false) ||
        (f.wasi."0.7.0".rustc-dep-of-std or false) ||
        (wasi."0.7.0"."rustc-dep-of-std" or false); }
      { "0.7.0"."rustc-std-workspace-alloc" =
        (f.wasi."0.7.0"."rustc-std-workspace-alloc" or false) ||
        (f.wasi."0.7.0".rustc-dep-of-std or false) ||
        (wasi."0.7.0"."rustc-dep-of-std" or false); }
      { "0.7.0".default = (f.wasi."0.7.0".default or true); }
    ];
  }) [];


# end
# winapi-0.3.8

  crates.winapi."0.3.8" = deps: { features?(features_.winapi."0.3.8" deps {}) }: buildRustCrate {
    crateName = "winapi";
    version = "0.3.8";
    description = "Raw FFI bindings for all of Windows API.";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "084ialbgww1vxry341fmkg5crgpvab3w52ahx1wa54yqjgym0vxs";
    build = "build.rs";
    dependencies = (if kernel == "i686-pc-windows-gnu" then mapFeatures features ([
      (crates."winapi_i686_pc_windows_gnu"."${deps."winapi"."0.3.8"."winapi_i686_pc_windows_gnu"}" deps)
    ]) else [])
      ++ (if kernel == "x86_64-pc-windows-gnu" then mapFeatures features ([
      (crates."winapi_x86_64_pc_windows_gnu"."${deps."winapi"."0.3.8"."winapi_x86_64_pc_windows_gnu"}" deps)
    ]) else []);
    features = mkFeatures (features."winapi"."0.3.8" or {});
  };
  features_.winapi."0.3.8" = deps: f: updateFeatures f (rec {
    winapi = fold recursiveUpdate {} [
      { "0.3.8"."impl-debug" =
        (f.winapi."0.3.8"."impl-debug" or false) ||
        (f.winapi."0.3.8".debug or false) ||
        (winapi."0.3.8"."debug" or false); }
      { "0.3.8".default = (f.winapi."0.3.8".default or true); }
    ];
    winapi_i686_pc_windows_gnu."${deps.winapi."0.3.8".winapi_i686_pc_windows_gnu}".default = true;
    winapi_x86_64_pc_windows_gnu."${deps.winapi."0.3.8".winapi_x86_64_pc_windows_gnu}".default = true;
  }) [
    (features_.winapi_i686_pc_windows_gnu."${deps."winapi"."0.3.8"."winapi_i686_pc_windows_gnu"}" deps)
    (features_.winapi_x86_64_pc_windows_gnu."${deps."winapi"."0.3.8"."winapi_x86_64_pc_windows_gnu"}" deps)
  ];


# end
# winapi-i686-pc-windows-gnu-0.4.0

  crates.winapi_i686_pc_windows_gnu."0.4.0" = deps: { features?(features_.winapi_i686_pc_windows_gnu."0.4.0" deps {}) }: buildRustCrate {
    crateName = "winapi-i686-pc-windows-gnu";
    version = "0.4.0";
    description = "Import libraries for the i686-pc-windows-gnu target. Please don't use this crate directly, depend on winapi instead.";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "05ihkij18r4gamjpxj4gra24514can762imjzlmak5wlzidplzrp";
    build = "build.rs";
  };
  features_.winapi_i686_pc_windows_gnu."0.4.0" = deps: f: updateFeatures f (rec {
    winapi_i686_pc_windows_gnu."0.4.0".default = (f.winapi_i686_pc_windows_gnu."0.4.0".default or true);
  }) [];


# end
# winapi-x86_64-pc-windows-gnu-0.4.0

  crates.winapi_x86_64_pc_windows_gnu."0.4.0" = deps: { features?(features_.winapi_x86_64_pc_windows_gnu."0.4.0" deps {}) }: buildRustCrate {
    crateName = "winapi-x86_64-pc-windows-gnu";
    version = "0.4.0";
    description = "Import libraries for the x86_64-pc-windows-gnu target. Please don't use this crate directly, depend on winapi instead.";
    authors = [ "Peter Atashian <retep998@gmail.com>" ];
    sha256 = "0n1ylmlsb8yg1v583i4xy0qmqg42275flvbc51hdqjjfjcl9vlbj";
    build = "build.rs";
  };
  features_.winapi_x86_64_pc_windows_gnu."0.4.0" = deps: f: updateFeatures f (rec {
    winapi_x86_64_pc_windows_gnu."0.4.0".default = (f.winapi_x86_64_pc_windows_gnu."0.4.0".default or true);
  }) [];


# end
# xdg-2.2.0

  crates.xdg."2.2.0" = deps: { features?(features_.xdg."2.2.0" deps {}) }: buildRustCrate {
    crateName = "xdg";
    version = "2.2.0";
    description = "A library for storing and retrieving files according to XDG Base Directory specification";
    authors = [ "Ben Longbons <b.r.longbons@gmail.com>" "whitequark <whitequark@whitequark.org>" ];
    sha256 = "1dxfcsxkkmp2dn51x5jbkw0nsg8lq397dkqwqd43d3914cnxjlip";
  };
  features_.xdg."2.2.0" = deps: f: updateFeatures f (rec {
    xdg."2.2.0".default = (f.xdg."2.2.0".default or true);
  }) [];


# end
}
