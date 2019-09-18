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
# ansi_term-0.11.0

  crates.ansi_term."0.11.0" = deps: { features?(features_.ansi_term."0.11.0" deps {}) }: buildRustCrate {
    crateName = "ansi_term";
    version = "0.11.0";
    description = "Library for ANSI terminal colours and styles (bold, underline)";
    authors = [ "ogham@bsago.me" "Ryan Scheel (Havvy) <ryan.havvy@gmail.com>" "Josh Triplett <josh@joshtriplett.org>" ];
    sha256 = "08fk0p2xvkqpmz3zlrwnf6l8sj2vngw464rvzspzp31sbgxbwm4v";
    dependencies = (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."ansi_term"."0.11.0"."winapi"}" deps)
    ]) else []);
  };
  features_.ansi_term."0.11.0" = deps: f: updateFeatures f (rec {
    ansi_term."0.11.0".default = (f.ansi_term."0.11.0".default or true);
    winapi = fold recursiveUpdate {} [
      { "${deps.ansi_term."0.11.0".winapi}"."consoleapi" = true; }
      { "${deps.ansi_term."0.11.0".winapi}"."errhandlingapi" = true; }
      { "${deps.ansi_term."0.11.0".winapi}"."processenv" = true; }
      { "${deps.ansi_term."0.11.0".winapi}".default = true; }
    ];
  }) [
    (features_.winapi."${deps."ansi_term"."0.11.0"."winapi"}" deps)
  ];


# end
# atty-0.2.13

  crates.atty."0.2.13" = deps: { features?(features_.atty."0.2.13" deps {}) }: buildRustCrate {
    crateName = "atty";
    version = "0.2.13";
    description = "A simple interface for querying atty";
    authors = [ "softprops <d.tangren@gmail.com>" ];
    sha256 = "0a1ii8h9fvvrq05bz7j135zjjz1sjz6n2invn2ngxqri0jxgmip2";
    dependencies = (if (kernel == "linux" || kernel == "darwin") then mapFeatures features ([
      (crates."libc"."${deps."atty"."0.2.13"."libc"}" deps)
    ]) else [])
      ++ (if kernel == "windows" then mapFeatures features ([
      (crates."winapi"."${deps."atty"."0.2.13"."winapi"}" deps)
    ]) else []);
  };
  features_.atty."0.2.13" = deps: f: updateFeatures f (rec {
    atty."0.2.13".default = (f.atty."0.2.13".default or true);
    libc."${deps.atty."0.2.13".libc}".default = (f.libc."${deps.atty."0.2.13".libc}".default or false);
    winapi = fold recursiveUpdate {} [
      { "${deps.atty."0.2.13".winapi}"."consoleapi" = true; }
      { "${deps.atty."0.2.13".winapi}"."minwinbase" = true; }
      { "${deps.atty."0.2.13".winapi}"."minwindef" = true; }
      { "${deps.atty."0.2.13".winapi}"."processenv" = true; }
      { "${deps.atty."0.2.13".winapi}"."winbase" = true; }
      { "${deps.atty."0.2.13".winapi}".default = true; }
    ];
  }) [
    (features_.libc."${deps."atty"."0.2.13"."libc"}" deps)
    (features_.winapi."${deps."atty"."0.2.13"."winapi"}" deps)
  ];


# end
# bitflags-1.1.0

  crates.bitflags."1.1.0" = deps: { features?(features_.bitflags."1.1.0" deps {}) }: buildRustCrate {
    crateName = "bitflags";
    version = "1.1.0";
    description = "A macro to generate structures which behave like bitflags.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1iwa4jrqcf4lnbwl562a3lx3r0jkh1j88b219bsqvbm4sni67dyv";
    build = "build.rs";
    features = mkFeatures (features."bitflags"."1.1.0" or {});
  };
  features_.bitflags."1.1.0" = deps: f: updateFeatures f (rec {
    bitflags."1.1.0".default = (f.bitflags."1.1.0".default or true);
  }) [];


# end
# clap-2.33.0

  crates.clap."2.33.0" = deps: { features?(features_.clap."2.33.0" deps {}) }: buildRustCrate {
    crateName = "clap";
    version = "2.33.0";
    description = "A simple to use, efficient, and full-featured Command Line Argument Parser\n";
    authors = [ "Kevin K. <kbknapp@gmail.com>" ];
    sha256 = "054n9ngh6pkknpmd4acgdsp40iw6f5jzq8a4h2b76gnbvk6p5xjh";
    dependencies = mapFeatures features ([
      (crates."bitflags"."${deps."clap"."2.33.0"."bitflags"}" deps)
      (crates."textwrap"."${deps."clap"."2.33.0"."textwrap"}" deps)
      (crates."unicode_width"."${deps."clap"."2.33.0"."unicode_width"}" deps)
    ]
      ++ (if features.clap."2.33.0".atty or false then [ (crates.atty."${deps."clap"."2.33.0".atty}" deps) ] else [])
      ++ (if features.clap."2.33.0".strsim or false then [ (crates.strsim."${deps."clap"."2.33.0".strsim}" deps) ] else [])
      ++ (if features.clap."2.33.0".vec_map or false then [ (crates.vec_map."${deps."clap"."2.33.0".vec_map}" deps) ] else []))
      ++ (if !(kernel == "windows") then mapFeatures features ([
    ]
      ++ (if features.clap."2.33.0".ansi_term or false then [ (crates.ansi_term."${deps."clap"."2.33.0".ansi_term}" deps) ] else [])) else []);
    features = mkFeatures (features."clap"."2.33.0" or {});
  };
  features_.clap."2.33.0" = deps: f: updateFeatures f (rec {
    ansi_term."${deps.clap."2.33.0".ansi_term}".default = true;
    atty."${deps.clap."2.33.0".atty}".default = true;
    bitflags."${deps.clap."2.33.0".bitflags}".default = true;
    clap = fold recursiveUpdate {} [
      { "2.33.0"."ansi_term" =
        (f.clap."2.33.0"."ansi_term" or false) ||
        (f.clap."2.33.0".color or false) ||
        (clap."2.33.0"."color" or false); }
      { "2.33.0"."atty" =
        (f.clap."2.33.0"."atty" or false) ||
        (f.clap."2.33.0".color or false) ||
        (clap."2.33.0"."color" or false); }
      { "2.33.0"."clippy" =
        (f.clap."2.33.0"."clippy" or false) ||
        (f.clap."2.33.0".lints or false) ||
        (clap."2.33.0"."lints" or false); }
      { "2.33.0"."color" =
        (f.clap."2.33.0"."color" or false) ||
        (f.clap."2.33.0".default or false) ||
        (clap."2.33.0"."default" or false); }
      { "2.33.0"."strsim" =
        (f.clap."2.33.0"."strsim" or false) ||
        (f.clap."2.33.0".suggestions or false) ||
        (clap."2.33.0"."suggestions" or false); }
      { "2.33.0"."suggestions" =
        (f.clap."2.33.0"."suggestions" or false) ||
        (f.clap."2.33.0".default or false) ||
        (clap."2.33.0"."default" or false); }
      { "2.33.0"."term_size" =
        (f.clap."2.33.0"."term_size" or false) ||
        (f.clap."2.33.0".wrap_help or false) ||
        (clap."2.33.0"."wrap_help" or false); }
      { "2.33.0"."vec_map" =
        (f.clap."2.33.0"."vec_map" or false) ||
        (f.clap."2.33.0".default or false) ||
        (clap."2.33.0"."default" or false); }
      { "2.33.0"."yaml" =
        (f.clap."2.33.0"."yaml" or false) ||
        (f.clap."2.33.0".doc or false) ||
        (clap."2.33.0"."doc" or false); }
      { "2.33.0"."yaml-rust" =
        (f.clap."2.33.0"."yaml-rust" or false) ||
        (f.clap."2.33.0".yaml or false) ||
        (clap."2.33.0"."yaml" or false); }
      { "2.33.0".default = (f.clap."2.33.0".default or true); }
    ];
    strsim."${deps.clap."2.33.0".strsim}".default = true;
    textwrap = fold recursiveUpdate {} [
      { "${deps.clap."2.33.0".textwrap}"."term_size" =
        (f.textwrap."${deps.clap."2.33.0".textwrap}"."term_size" or false) ||
        (clap."2.33.0"."wrap_help" or false) ||
        (f."clap"."2.33.0"."wrap_help" or false); }
      { "${deps.clap."2.33.0".textwrap}".default = true; }
    ];
    unicode_width."${deps.clap."2.33.0".unicode_width}".default = true;
    vec_map."${deps.clap."2.33.0".vec_map}".default = true;
  }) [
    (features_.atty."${deps."clap"."2.33.0"."atty"}" deps)
    (features_.bitflags."${deps."clap"."2.33.0"."bitflags"}" deps)
    (features_.strsim."${deps."clap"."2.33.0"."strsim"}" deps)
    (features_.textwrap."${deps."clap"."2.33.0"."textwrap"}" deps)
    (features_.unicode_width."${deps."clap"."2.33.0"."unicode_width"}" deps)
    (features_.vec_map."${deps."clap"."2.33.0"."vec_map"}" deps)
    (features_.ansi_term."${deps."clap"."2.33.0"."ansi_term"}" deps)
  ];


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
# libc-0.2.62

  crates.libc."0.2.62" = deps: { features?(features_.libc."0.2.62" deps {}) }: buildRustCrate {
    crateName = "libc";
    version = "0.2.62";
    description = "Raw FFI bindings to platform libraries like libc.\n";
    authors = [ "The Rust Project Developers" ];
    sha256 = "1vsb4pyn6gl6sri6cv5hin5wjfgk7lk2bshzmxb1xnkckjhz4gbx";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."libc"."0.2.62" or {});
  };
  features_.libc."0.2.62" = deps: f: updateFeatures f (rec {
    libc = fold recursiveUpdate {} [
      { "0.2.62"."align" =
        (f.libc."0.2.62"."align" or false) ||
        (f.libc."0.2.62".rustc-dep-of-std or false) ||
        (libc."0.2.62"."rustc-dep-of-std" or false); }
      { "0.2.62"."rustc-std-workspace-core" =
        (f.libc."0.2.62"."rustc-std-workspace-core" or false) ||
        (f.libc."0.2.62".rustc-dep-of-std or false) ||
        (libc."0.2.62"."rustc-dep-of-std" or false); }
      { "0.2.62"."std" =
        (f.libc."0.2.62"."std" or false) ||
        (f.libc."0.2.62".default or false) ||
        (libc."0.2.62"."default" or false) ||
        (f.libc."0.2.62".use_std or false) ||
        (libc."0.2.62"."use_std" or false); }
      { "0.2.62".default = (f.libc."0.2.62".default or true); }
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
# proc-macro2-1.0.3

  crates.proc_macro2."1.0.3" = deps: { features?(features_.proc_macro2."1.0.3" deps {}) }: buildRustCrate {
    crateName = "proc-macro2";
    version = "1.0.3";
    description = "A stable implementation of the upcoming new `proc_macro` API. Comes with an\noption, off by default, to also reimplement itself in terms of the upstream\nunstable API.\n";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" ];
    edition = "2018";
    sha256 = "0qv29h6pz6n0b4qi8w240l3xppsw26bk5ga2vcjk3nhji0nsplwk";
    libName = "proc_macro2";
    dependencies = mapFeatures features ([
      (crates."unicode_xid"."${deps."proc_macro2"."1.0.3"."unicode_xid"}" deps)
    ]);
    features = mkFeatures (features."proc_macro2"."1.0.3" or {});
  };
  features_.proc_macro2."1.0.3" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "1.0.3"."proc-macro" =
        (f.proc_macro2."1.0.3"."proc-macro" or false) ||
        (f.proc_macro2."1.0.3".default or false) ||
        (proc_macro2."1.0.3"."default" or false); }
      { "1.0.3".default = (f.proc_macro2."1.0.3".default or true); }
    ];
    unicode_xid."${deps.proc_macro2."1.0.3".unicode_xid}".default = true;
  }) [
    (features_.unicode_xid."${deps."proc_macro2"."1.0.3"."unicode_xid"}" deps)
  ];


# end
# quote-1.0.2

  crates.quote."1.0.2" = deps: { features?(features_.quote."1.0.2" deps {}) }: buildRustCrate {
    crateName = "quote";
    version = "1.0.2";
    description = "Quasi-quoting macro quote!(...)";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    edition = "2018";
    sha256 = "0r7030w7dymarn92gjgm02hsm04fwsfs6f1l20wdqiyrm9z8rs5q";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."quote"."1.0.2"."proc_macro2"}" deps)
    ]);
    features = mkFeatures (features."quote"."1.0.2" or {});
  };
  features_.quote."1.0.2" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "${deps.quote."1.0.2".proc_macro2}"."proc-macro" =
        (f.proc_macro2."${deps.quote."1.0.2".proc_macro2}"."proc-macro" or false) ||
        (quote."1.0.2"."proc-macro" or false) ||
        (f."quote"."1.0.2"."proc-macro" or false); }
      { "${deps.quote."1.0.2".proc_macro2}".default = (f.proc_macro2."${deps.quote."1.0.2".proc_macro2}".default or false); }
    ];
    quote = fold recursiveUpdate {} [
      { "1.0.2"."proc-macro" =
        (f.quote."1.0.2"."proc-macro" or false) ||
        (f.quote."1.0.2".default or false) ||
        (quote."1.0.2"."default" or false); }
      { "1.0.2".default = (f.quote."1.0.2".default or true); }
    ];
  }) [
    (features_.proc_macro2."${deps."quote"."1.0.2"."proc_macro2"}" deps)
  ];


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
# ryu-1.0.0

  crates.ryu."1.0.0" = deps: { features?(features_.ryu."1.0.0" deps {}) }: buildRustCrate {
    crateName = "ryu";
    version = "1.0.0";
    description = "Fast floating point to string conversion";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0hysqba7hi31xw1jka8jh7qb4m9fx5l6vik55wpc3rpsg46cwgbf";
    build = "build.rs";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."ryu"."1.0.0" or {});
  };
  features_.ryu."1.0.0" = deps: f: updateFeatures f (rec {
    ryu."1.0.0".default = (f.ryu."1.0.0".default or true);
  }) [];


# end
# serde-1.0.101

  crates.serde."1.0.101" = deps: { features?(features_.serde."1.0.101" deps {}) }: buildRustCrate {
    crateName = "serde";
    version = "1.0.101";
    description = "A generic serialization/deserialization framework";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "0sacv3njx99yr8gxsl80cy1h98b9vd1pv6aa8ncbnk0pys8r82vn";
    build = "build.rs";
    dependencies = mapFeatures features ([
    ]
      ++ (if features.serde."1.0.101".serde_derive or false then [ (crates.serde_derive."${deps."serde"."1.0.101".serde_derive}" deps) ] else []));
    features = mkFeatures (features."serde"."1.0.101" or {});
  };
  features_.serde."1.0.101" = deps: f: updateFeatures f (rec {
    serde = fold recursiveUpdate {} [
      { "1.0.101"."serde_derive" =
        (f.serde."1.0.101"."serde_derive" or false) ||
        (f.serde."1.0.101".derive or false) ||
        (serde."1.0.101"."derive" or false); }
      { "1.0.101"."std" =
        (f.serde."1.0.101"."std" or false) ||
        (f.serde."1.0.101".default or false) ||
        (serde."1.0.101"."default" or false); }
      { "1.0.101".default = (f.serde."1.0.101".default or true); }
    ];
    serde_derive."${deps.serde."1.0.101".serde_derive}".default = true;
  }) [
    (features_.serde_derive."${deps."serde"."1.0.101"."serde_derive"}" deps)
  ];


# end
# serde_derive-1.0.101

  crates.serde_derive."1.0.101" = deps: { features?(features_.serde_derive."1.0.101" deps {}) }: buildRustCrate {
    crateName = "serde_derive";
    version = "1.0.101";
    description = "Macros 1.1 implementation of #[derive(Serialize, Deserialize)]";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "093x99qff1ihjmy32fp1gxp66qh0nni349j20y3w0h33wqk19dr0";
    procMacro = true;
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."serde_derive"."1.0.101"."proc_macro2"}" deps)
      (crates."quote"."${deps."serde_derive"."1.0.101"."quote"}" deps)
      (crates."syn"."${deps."serde_derive"."1.0.101"."syn"}" deps)
    ]);
    features = mkFeatures (features."serde_derive"."1.0.101" or {});
  };
  features_.serde_derive."1.0.101" = deps: f: updateFeatures f (rec {
    proc_macro2."${deps.serde_derive."1.0.101".proc_macro2}".default = true;
    quote."${deps.serde_derive."1.0.101".quote}".default = true;
    serde_derive."1.0.101".default = (f.serde_derive."1.0.101".default or true);
    syn = fold recursiveUpdate {} [
      { "${deps.serde_derive."1.0.101".syn}"."visit" = true; }
      { "${deps.serde_derive."1.0.101".syn}".default = true; }
    ];
  }) [
    (features_.proc_macro2."${deps."serde_derive"."1.0.101"."proc_macro2"}" deps)
    (features_.quote."${deps."serde_derive"."1.0.101"."quote"}" deps)
    (features_.syn."${deps."serde_derive"."1.0.101"."syn"}" deps)
  ];


# end
# serde_json-1.0.40

  crates.serde_json."1.0.40" = deps: { features?(features_.serde_json."1.0.40" deps {}) }: buildRustCrate {
    crateName = "serde_json";
    version = "1.0.40";
    description = "A JSON serialization file format";
    authors = [ "Erick Tryzelaar <erick.tryzelaar@gmail.com>" "David Tolnay <dtolnay@gmail.com>" ];
    sha256 = "1wf8lkisjvyg4ghp2fwm3ysymjy66l030l8d7p6033wiayfzpyh3";
    dependencies = mapFeatures features ([
      (crates."itoa"."${deps."serde_json"."1.0.40"."itoa"}" deps)
      (crates."ryu"."${deps."serde_json"."1.0.40"."ryu"}" deps)
      (crates."serde"."${deps."serde_json"."1.0.40"."serde"}" deps)
    ]);
    features = mkFeatures (features."serde_json"."1.0.40" or {});
  };
  features_.serde_json."1.0.40" = deps: f: updateFeatures f (rec {
    itoa."${deps.serde_json."1.0.40".itoa}".default = true;
    ryu."${deps.serde_json."1.0.40".ryu}".default = true;
    serde."${deps.serde_json."1.0.40".serde}".default = true;
    serde_json = fold recursiveUpdate {} [
      { "1.0.40"."indexmap" =
        (f.serde_json."1.0.40"."indexmap" or false) ||
        (f.serde_json."1.0.40".preserve_order or false) ||
        (serde_json."1.0.40"."preserve_order" or false); }
      { "1.0.40".default = (f.serde_json."1.0.40".default or true); }
    ];
  }) [
    (features_.itoa."${deps."serde_json"."1.0.40"."itoa"}" deps)
    (features_.ryu."${deps."serde_json"."1.0.40"."ryu"}" deps)
    (features_.serde."${deps."serde_json"."1.0.40"."serde"}" deps)
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
# strsim-0.8.0

  crates.strsim."0.8.0" = deps: { features?(features_.strsim."0.8.0" deps {}) }: buildRustCrate {
    crateName = "strsim";
    version = "0.8.0";
    description = "Implementations of string similarity metrics.\nIncludes Hamming, Levenshtein, OSA, Damerau-Levenshtein, Jaro, and Jaro-Winkler.\n";
    authors = [ "Danny Guo <dannyguo91@gmail.com>" ];
    sha256 = "0d3jsdz22wgjyxdakqnvdgmwjdvkximz50d9zfk4qlalw635qcvy";
  };
  features_.strsim."0.8.0" = deps: f: updateFeatures f (rec {
    strsim."0.8.0".default = (f.strsim."0.8.0".default or true);
  }) [];


# end
# syn-1.0.5

  crates.syn."1.0.5" = deps: { features?(features_.syn."1.0.5" deps {}) }: buildRustCrate {
    crateName = "syn";
    version = "1.0.5";
    description = "Parser for Rust source code";
    authors = [ "David Tolnay <dtolnay@gmail.com>" ];
    edition = "2018";
    sha256 = "08qbk425r8c4q4rrpq1q9wkd3v3bji8nlfaxj8v4l7lkpjkh0xgs";
    dependencies = mapFeatures features ([
      (crates."proc_macro2"."${deps."syn"."1.0.5"."proc_macro2"}" deps)
      (crates."unicode_xid"."${deps."syn"."1.0.5"."unicode_xid"}" deps)
    ]
      ++ (if features.syn."1.0.5".quote or false then [ (crates.quote."${deps."syn"."1.0.5".quote}" deps) ] else []));
    features = mkFeatures (features."syn"."1.0.5" or {});
  };
  features_.syn."1.0.5" = deps: f: updateFeatures f (rec {
    proc_macro2 = fold recursiveUpdate {} [
      { "${deps.syn."1.0.5".proc_macro2}"."proc-macro" =
        (f.proc_macro2."${deps.syn."1.0.5".proc_macro2}"."proc-macro" or false) ||
        (syn."1.0.5"."proc-macro" or false) ||
        (f."syn"."1.0.5"."proc-macro" or false); }
      { "${deps.syn."1.0.5".proc_macro2}".default = (f.proc_macro2."${deps.syn."1.0.5".proc_macro2}".default or false); }
    ];
    quote = fold recursiveUpdate {} [
      { "${deps.syn."1.0.5".quote}"."proc-macro" =
        (f.quote."${deps.syn."1.0.5".quote}"."proc-macro" or false) ||
        (syn."1.0.5"."proc-macro" or false) ||
        (f."syn"."1.0.5"."proc-macro" or false); }
      { "${deps.syn."1.0.5".quote}".default = (f.quote."${deps.syn."1.0.5".quote}".default or false); }
    ];
    syn = fold recursiveUpdate {} [
      { "1.0.5"."clone-impls" =
        (f.syn."1.0.5"."clone-impls" or false) ||
        (f.syn."1.0.5".default or false) ||
        (syn."1.0.5"."default" or false); }
      { "1.0.5"."derive" =
        (f.syn."1.0.5"."derive" or false) ||
        (f.syn."1.0.5".default or false) ||
        (syn."1.0.5"."default" or false); }
      { "1.0.5"."parsing" =
        (f.syn."1.0.5"."parsing" or false) ||
        (f.syn."1.0.5".default or false) ||
        (syn."1.0.5"."default" or false); }
      { "1.0.5"."printing" =
        (f.syn."1.0.5"."printing" or false) ||
        (f.syn."1.0.5".default or false) ||
        (syn."1.0.5"."default" or false); }
      { "1.0.5"."proc-macro" =
        (f.syn."1.0.5"."proc-macro" or false) ||
        (f.syn."1.0.5".default or false) ||
        (syn."1.0.5"."default" or false); }
      { "1.0.5"."quote" =
        (f.syn."1.0.5"."quote" or false) ||
        (f.syn."1.0.5".printing or false) ||
        (syn."1.0.5"."printing" or false); }
      { "1.0.5".default = (f.syn."1.0.5".default or true); }
    ];
    unicode_xid."${deps.syn."1.0.5".unicode_xid}".default = true;
  }) [
    (features_.proc_macro2."${deps."syn"."1.0.5"."proc_macro2"}" deps)
    (features_.quote."${deps."syn"."1.0.5"."quote"}" deps)
    (features_.unicode_xid."${deps."syn"."1.0.5"."unicode_xid"}" deps)
  ];


# end
# textwrap-0.11.0

  crates.textwrap."0.11.0" = deps: { features?(features_.textwrap."0.11.0" deps {}) }: buildRustCrate {
    crateName = "textwrap";
    version = "0.11.0";
    description = "Textwrap is a small library for word wrapping, indenting, and\ndedenting strings.\n\nYou can use it to format strings (such as help and error messages) for\ndisplay in commandline applications. It is designed to be efficient\nand handle Unicode characters correctly.\n";
    authors = [ "Martin Geisler <martin@geisler.net>" ];
    sha256 = "0s25qh49n7kjayrdj4q3v0jk0jc6vy88rdw0bvgfxqlscpqpxi7d";
    dependencies = mapFeatures features ([
      (crates."unicode_width"."${deps."textwrap"."0.11.0"."unicode_width"}" deps)
    ]);
  };
  features_.textwrap."0.11.0" = deps: f: updateFeatures f (rec {
    textwrap."0.11.0".default = (f.textwrap."0.11.0".default or true);
    unicode_width."${deps.textwrap."0.11.0".unicode_width}".default = true;
  }) [
    (features_.unicode_width."${deps."textwrap"."0.11.0"."unicode_width"}" deps)
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
# unicode-width-0.1.6

  crates.unicode_width."0.1.6" = deps: { features?(features_.unicode_width."0.1.6" deps {}) }: buildRustCrate {
    crateName = "unicode-width";
    version = "0.1.6";
    description = "Determine displayed width of `char` and `str` types\naccording to Unicode Standard Annex #11 rules.\n";
    authors = [ "kwantam <kwantam@gmail.com>" ];
    sha256 = "1mss965j7d8pv7z7zg6qfkcb7lyhxkxvbh8akzr4xxxx3vzazwsi";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."unicode_width"."0.1.6" or {});
  };
  features_.unicode_width."0.1.6" = deps: f: updateFeatures f (rec {
    unicode_width = fold recursiveUpdate {} [
      { "0.1.6"."compiler_builtins" =
        (f.unicode_width."0.1.6"."compiler_builtins" or false) ||
        (f.unicode_width."0.1.6".rustc-dep-of-std or false) ||
        (unicode_width."0.1.6"."rustc-dep-of-std" or false); }
      { "0.1.6"."core" =
        (f.unicode_width."0.1.6"."core" or false) ||
        (f.unicode_width."0.1.6".rustc-dep-of-std or false) ||
        (unicode_width."0.1.6"."rustc-dep-of-std" or false); }
      { "0.1.6"."std" =
        (f.unicode_width."0.1.6"."std" or false) ||
        (f.unicode_width."0.1.6".rustc-dep-of-std or false) ||
        (unicode_width."0.1.6"."rustc-dep-of-std" or false); }
      { "0.1.6".default = (f.unicode_width."0.1.6".default or true); }
    ];
  }) [];


# end
# unicode-xid-0.2.0

  crates.unicode_xid."0.2.0" = deps: { features?(features_.unicode_xid."0.2.0" deps {}) }: buildRustCrate {
    crateName = "unicode-xid";
    version = "0.2.0";
    description = "Determine whether characters have the XID_Start\nor XID_Continue properties according to\nUnicode Standard Annex #31.\n";
    authors = [ "erick.tryzelaar <erick.tryzelaar@gmail.com>" "kwantam <kwantam@gmail.com>" ];
    sha256 = "1c85gb3p3qhbjvfyjb31m06la4f024jx319k10ig7n47dz2fk8v7";
    features = mkFeatures (features."unicode_xid"."0.2.0" or {});
  };
  features_.unicode_xid."0.2.0" = deps: f: updateFeatures f (rec {
    unicode_xid."0.2.0".default = (f.unicode_xid."0.2.0".default or true);
  }) [];


# end
# vec_map-0.8.1

  crates.vec_map."0.8.1" = deps: { features?(features_.vec_map."0.8.1" deps {}) }: buildRustCrate {
    crateName = "vec_map";
    version = "0.8.1";
    description = "A simple map based on a vector for small integer keys";
    authors = [ "Alex Crichton <alex@alexcrichton.com>" "Jorge Aparicio <japaricious@gmail.com>" "Alexis Beingessner <a.beingessner@gmail.com>" "Brian Anderson <>" "tbu- <>" "Manish Goregaokar <>" "Aaron Turon <aturon@mozilla.com>" "Adolfo Ochagavía <>" "Niko Matsakis <>" "Steven Fackler <>" "Chase Southwood <csouth3@illinois.edu>" "Eduard Burtescu <>" "Florian Wilkens <>" "Félix Raimundo <>" "Tibor Benke <>" "Markus Siemens <markus@m-siemens.de>" "Josh Branchaud <jbranchaud@gmail.com>" "Huon Wilson <dbau.pp@gmail.com>" "Corey Farwell <coref@rwell.org>" "Aaron Liblong <>" "Nick Cameron <nrc@ncameron.org>" "Patrick Walton <pcwalton@mimiga.net>" "Felix S Klock II <>" "Andrew Paseltiner <apaseltiner@gmail.com>" "Sean McArthur <sean.monstar@gmail.com>" "Vadim Petrochenkov <>" ];
    sha256 = "1jj2nrg8h3l53d43rwkpkikq5a5x15ms4rf1rw92hp5lrqhi8mpi";
    dependencies = mapFeatures features ([
]);
    features = mkFeatures (features."vec_map"."0.8.1" or {});
  };
  features_.vec_map."0.8.1" = deps: f: updateFeatures f (rec {
    vec_map = fold recursiveUpdate {} [
      { "0.8.1"."serde" =
        (f.vec_map."0.8.1"."serde" or false) ||
        (f.vec_map."0.8.1".eders or false) ||
        (vec_map."0.8.1"."eders" or false); }
      { "0.8.1".default = (f.vec_map."0.8.1".default or true); }
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
