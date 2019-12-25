#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -A foo ./10-foo-bar.nix

if command -v foo >/dev/null 2>&1; then
	foo
else
	echo cant-find-foo
fi

if command -v bar >/dev/null 2>&1; then
	bar
else
	echo cant-find-bar
fi
