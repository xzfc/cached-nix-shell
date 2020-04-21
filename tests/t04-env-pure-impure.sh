#!/bin/sh
. ./lib.sh

put tmp/prefix.nix << 'EOF'
with import <nixpkgs> { };
let
  add-prefix = stdenv.mkDerivation {
    name = "cached-nix-shell-test-add-prefix";
    unpackPhase = ":";
    installPhase = ":";
    setupHook = writeText "setup-hook" ''
      export FOO=prefix:$FOO
    '';
  };
in mkShell { buildInputs = [ add-prefix ]; }
EOF

export FOO=foo-value
unset BAR


run cached-nix-shell -p --run 'echo ${FOO-doesnt-have-foo}'
check_contains "^foo-value$"

run cached-nix-shell -p --pure --run 'echo ${FOO-doesnt-have-foo}'
check_contains "^doesnt-have-foo$"
check_fast

run cached-nix-shell -p --pure --keep FOO --run 'echo ${FOO-doesnt-have-foo}'
check_contains "^foo-value$"
# TODO: this should not invalidate the cache
skip check_fast


run cached-nix-shell ./tmp/prefix.nix --keep FOO \
	--run 'echo ${FOO-doesnt-have-foo}'
check_contains "^prefix:foo-value$"

run cached-nix-shell ./tmp/prefix.nix --pure --keep FOO \
	--run 'echo ${FOO-doesnt-have-foo}'
check_contains "^prefix:foo-value$"
check_fast

export BAR=bar-value
run cached-nix-shell ./tmp/prefix.nix --pure --keep FOO --keep BAR \
	--run 'echo ${FOO-doesnt-have-foo}; echo ${BAR-doesnt-have-bar}'
check_contains "^prefix:foo-value$"
check_contains "^bar-value$"
# TODO: this should not invalidate the cache
skip check_fast
