#!/bin/sh
. ./lib.sh
# Check the normalization of PWD.  The cache should evaluate in the directory
# containing default.nix no matter the current PWD or the way the path to
# default.nix is specified.  This behavior doesn't match the behavior of
# nix-shell, but this test case checks that at least it is consistent.

mkdir tmp/foo tmp/bar
put +x ./tmp/foo/default.nix << 'EOF'
with import <nixpkgs> { }; mkShell {
	shellHook = ''printf '%s\n' "$PWD" > "$GOT"'';
}
EOF

check_normalized_pwd() {
	rm -f "$GOT" tmp/cache/cached-nix-shell/*
	run env --chdir "$1" cached-nix-shell --keep GOT "$2" --run :
	check "got $(cat tmp/got)" cmp -s tmp/expected tmp/got
}

export GOT=$PWD/tmp/got
printf "%s\n" "$PWD/tmp/foo" > "$PWD/tmp/expected"
printf "Expected: %s\n" "$PWD/tmp/foo"

check_normalized_pwd . tmp/foo
check_normalized_pwd . tmp/foo/
check_normalized_pwd . tmp/foo/default.nix

check_normalized_pwd . ./tmp/foo
check_normalized_pwd . ./tmp/foo/
check_normalized_pwd . ./tmp/foo/default.nix

check_normalized_pwd . "$PWD"/tmp/foo
check_normalized_pwd . "$PWD"/tmp/foo/
check_normalized_pwd . "$PWD"/tmp/foo/default.nix

check_normalized_pwd tmp/foo ""
check_normalized_pwd tmp/foo .
check_normalized_pwd tmp/foo ./default.nix
check_normalized_pwd tmp/foo default.nix

check_normalized_pwd tmp/bar ../foo
check_normalized_pwd tmp/bar ../foo/
check_normalized_pwd tmp/bar ../foo/default.nix
