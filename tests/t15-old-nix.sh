#!/bin/sh
. ./lib.sh
# Check that cached-nix-shell works even if the $PATH contains an old derivation
# of nix-shell. https://github.com/xzfc/cached-nix-shell/issues/24

# release-18.03
PATH=$(
	nix-shell \
		-I old=https://github.com/nixos/nixpkgs/archive/3e1be2206b4c1eb3299fb633b8ce9f5ac1c32898.tar.gz \
		-p '(import <old> {}).nix' --run 'dirname $(type -p nix-shell)'
):$PATH run cached-nix-shell -p --exec nix-shell --version
check_contains '^nix-shell (Nix) 2\.0\.4$'
