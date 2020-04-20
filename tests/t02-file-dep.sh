#!/bin/sh
. ./lib.sh
# Check that cache in invalidated when indirecly used .nix file is updated.

put ./tmp/small.nix << 'EOF'
{ stdenv }:
let str = import ./foo.nix;
in stdenv.mkDerivation {
  name = "cached-nix-shell-test";
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    echo 'echo ${str}' > $out/bin/x
    chmod +x $out/bin/x
  '';
}
EOF

put +x ./tmp/run << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p "callPackage ./small.nix {}"
x
EOF


echo '"val1"' > ./tmp/foo.nix
run ./tmp/run
check_contains val1
check_slow

run ./tmp/run
check_contains val1
check_fast

echo '"val2"' > ./tmp/foo.nix
run ./tmp/run
check_contains val2
check_slow
