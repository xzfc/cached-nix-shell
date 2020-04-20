#!/bin/sh
. ./lib.sh

put ./tmp/readdir.nix << 'EOF'
with import <nixpkgs> { };
mkShell { x = builtins.toJSON (builtins.readDir ./dir); }
EOF


mkdir -p tmp/dir/a
ln -s c tmp/dir/b
touch tmp/dir/c
run cached-nix-shell ./tmp/readdir.nix --run 'echo $x'
check_contains '^{"a":"directory","b":"symlink","c":"regular"}$'
check_slow

run cached-nix-shell ./tmp/readdir.nix --run 'echo $x'
check_contains '^{"a":"directory","b":"symlink","c":"regular"}$'
check_fast

rm tmp/dir/b
touch tmp/dir/b
run cached-nix-shell ./tmp/readdir.nix --run 'echo $x'
check_contains '^{"a":"directory","b":"regular","c":"regular"}$'
check_slow
