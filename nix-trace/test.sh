#!/usr/bin/env sh

run() {
	rm -f test-tmp/log
	LD_PRELOAD=$PWD/build/trace-nix.so TRACE_NIX=test-tmp/log \
		nix-shell --run : -p -- "$@" 2>/dev/null
}

result=0

dir_md5sum() {
	find "$1" -mindepth 1 -maxdepth 1 -printf '%P=%y\0' |
		sed -z 's/[^dlf]$/u/' |
		LC_ALL=C sort -z |
		md5sum |
		head -c 32
}

check() {
	local name="$1" string="$2"
	if grep -qzFx "$string" test-tmp/log; then
		printf "\x1b[32mOK: %s\x1b[m\n" "$name"
	else
		printf "\x1b[31mFail: %s\x1b[m\n" "$name"
		result=1
	fi
}

rm -rf test-tmp
mkdir test-tmp
echo '"foo"' > test-tmp/test.nix

run 'with import <unstable> {}; bash'
check import-channel L/nix/var/nix/profiles/per-user/root/channels/unstable

run 'with import <nonexistentChannel> {}; bash'
check import-channel-ne s/nix/var/nix/profiles/per-user/root/channels/nonexistentChannel


run 'import ./test-tmp/test.nix'
check import-relative-nix "l$PWD/test-tmp/test.nix"

run 'import ./nonexistent.nix'
check import-relative-nix-ne "s$PWD/nonexistent.nix"


run 'builtins.readFile ./test-tmp/test.nix'
check builtins.readFile "F$PWD/test-tmp/test.nix"
check builtins.readFile-md5 "$(md5sum ./test-tmp/test.nix | head -c 32)"

run 'builtins.readFile "/nonexistent/readFile"'
check builtins.readFile-ne "f/nonexistent/readFile"


run 'builtins.readDir ./test-tmp'
check builtins.readDir "D$PWD/test-tmp"
check builtins.readDir-md5 "$(dir_md5sum ./test-tmp)"

run 'builtins.readDir "/nonexistent/readDir"'
check builtins.readDir-ne "d/nonexistent/readDir"

exit $1
