#!/bin/sh
. ./lib.sh
# Check that cache in invalidated when indirecly used .nix file is updated.

put ./tmp/small.nix << 'EOF'
with import <nixpkgs> { };
mkShell { VAR = import ./foo.nix; }
EOF


echo '"val1"' > ./tmp/foo.nix
run cached-nix-shell ./tmp/small.nix --run 'echo $VAR'
check_contains '^val1$'
check_slow

run cached-nix-shell ./tmp/small.nix --run 'echo $VAR'
check_contains '^val1$'
check_fast

echo '"val2"' > ./tmp/foo.nix
run cached-nix-shell ./tmp/small.nix --run 'echo $VAR'
check_contains '^val2$'
check_slow
