#!/bin/sh
. ./lib.sh
# Ensure that the output of shellHook does not screw the environment variables.

put ./tmp/shell.nix << 'EOF'
with import <nixpkgs> { }; mkShell { shellHook = "echo hello$((6*7))world"; }
EOF

run cached-nix-shell ./tmp/shell.nix --run 'env > tmp/env'

check_contains hello42world

check "tmp/env does not contain hello42world" \
	not grep -q hello42world tmp/env
