#!/bin/sh
. ./lib.sh
# Check that cached-nix-shell works even if the $PATH contains an old derivation
# of nix-shell. https://github.com/xzfc/cached-nix-shell/issues/24

PATH=$(nix-build '<old>' -A nix --no-out-link -I \
	old=https://github.com/NixOS/nixpkgs/archive/nixos-21.05.tar.gz
	)/bin:$PATH run cached-nix-shell -p --exec nix-shell --version
check_contains '^nix-shell (Nix) 2\.3\.16$'
