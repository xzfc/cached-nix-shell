#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p stdenv --pure

if command -v some_bin; then
	some_bin
else
	echo cant-find-some-bin
fi
