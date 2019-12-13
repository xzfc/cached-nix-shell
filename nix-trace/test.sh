#!/usr/bin/env sh

run() {
	rm -f build/log
	LD_PRELOAD=$PWD/build/trace-nix.so TRACE_NIX_FD=42 42>build/log \
		nix-shell --run : -p -- "$@" 2>/dev/null
}

result=0

check() {
	local name="$1" string="$2"
	if grep -qzFx "$string" build/log; then
		printf "\x1b[32mOk: %s\x1b[m\n" "$name"
	else
		printf "\x1b[31mFail: %s\x1b[m\n" "$name"
		result=1
	fi
}

run 'with import <nonexistentChannel> {}; bash'
check import-channel /nix/var/nix/profiles/per-user/root/channels/nonexistentChannel

run 'import ./nonexistent.nix'
check import-relative-nix "$PWD/nonexistent.nix" build/log

run 'builtins.readFile "/nonexistent/readFile"'
check builtins.readFile "/nonexistent/readFile" build/log

run 'builtins.readDir "/nonexistent/readDir"'
check builtins.readDir "/nonexistent/readDir" build/log

exit $1
