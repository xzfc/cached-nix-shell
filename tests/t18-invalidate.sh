#!/bin/sh
. ./lib.sh
# Check that the cache is invalidated when a dependency is deleted.

put tmp/shell.nix << 'EOF'
with import <nixpkgs> { };
let
  dep = stdenv.mkDerivation {
    name = "cached-nix-shell-test-inner-dep";
    unpackPhase = ": | md5sum | cut -c 1-32 > $out";
  };
in mkShell { inherit dep; }
EOF

run cached-nix-shell tmp/shell.nix --pure --run 'cat $dep; echo $dep > tmp/dep'
check_contains d41d8cd98f00b204e9800998ecf8427e
check_slow

run cached-nix-shell tmp/shell.nix --pure --run 'cat $dep'
check_contains d41d8cd98f00b204e9800998ecf8427e
check_fast

run nix-store --delete $(cat tmp/dep)

run cached-nix-shell tmp/shell.nix --pure --run 'cat $dep'
check_contains d41d8cd98f00b204e9800998ecf8427e
check_slow
