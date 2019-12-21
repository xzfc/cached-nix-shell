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
	local name="$1" key="$2" val="$3"

	if ! grep -qzFx -- "$key" test-tmp/log; then
		printf "\x1b[31mFail: %s: can't find key\x1b[m\n" "$name"
		return
		result=1
	fi

	local actual_val="$(grep -zFx -A1 -- "$key" test-tmp/log | tail -zn1 | tr -d '\0')"
	if [ "$val" != "$actual_val" ]; then
		printf "\x1b[31mFail: %s: expected '%s', got '%s'\x1b[m\n" \
			"$name" "$val" "$actual_val"
		return
		result=1
	fi

	printf "\x1b[32mOK: %s\x1b[m\n" "$name"
}

rm -rf test-tmp
mkdir test-tmp
echo '"foo"' > test-tmp/test.nix

x=""
for i in {1..64};do
	x=x$x
	mkdir -p test-tmp/many-dirs/$x
done

run 'with import <unstable> {}; bash'
check import-channel \
	"s/nix/var/nix/profiles/per-user/root/channels/unstable" \
	"$(readlink /nix/var/nix/profiles/per-user/root/channels/unstable)"

run 'with import <nonexistentChannel> {}; bash'
check import-channel-ne \
	"s/nix/var/nix/profiles/per-user/root/channels/nonexistentChannel" '-'


run 'import ./test-tmp/test.nix'
check import-relative-nix \
	"s$PWD/test-tmp/test.nix" "+"

run 'import ./nonexistent.nix'
check import-relative-nix-ne \
	"s$PWD/nonexistent.nix" "-"


run 'builtins.readFile ./test-tmp/test.nix'
check builtins.readFile \
	"f$PWD/test-tmp/test.nix" \
	"$(md5sum ./test-tmp/test.nix | head -c 32)"

run 'builtins.readFile "/nonexistent/readFile"'
check builtins.readFile-ne \
	"f/nonexistent/readFile" "-"


run 'builtins.readDir ./test-tmp'
check builtins.readDir \
	"d$PWD/test-tmp" "$(dir_md5sum ./test-tmp)"

run 'builtins.readDir "/nonexistent/readDir"'
check builtins.readDir-ne \
	"d/nonexistent/readDir" "-"


run 'builtins.readDir ./test-tmp/many-dirs'
check builtins.readDir-many-dirs \
	"d$PWD/test-tmp/many-dirs" "$(dir_md5sum ./test-tmp/many-dirs)"

exit $result
