#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p hello --pure

if command -v some_bin >/dev/null 2>&1; then
	some_bin
else
	echo cant-find-some-bin
fi
hello
