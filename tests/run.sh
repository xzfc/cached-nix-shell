#!/bin/sh

cd "$(dirname -- $0)"
rm -rf ~/.cache/cached-nix-shell

run() {
	rm -f time.tmp out.tmp
	printf "Running %s\n" "$*"
	time -o time.tmp -f "%e" -- "$@" > out.tmp
}

check() {
	local text=$1
	shift
	if "$@";then
		printf "\x1b[32m+ %s\x1b[m\n" "$text"
	else
		printf "\x1b[31m- %s\x1b[m\n" "$text"
	fi
}

check_contains() { check "contains $1"   grep -q "$1" out.tmp; }
check_slow() { check "slow ($(cat time.tmp))"  grep -vq "^0.0" time.tmp; }
check_fast() { check "fast ($(cat time.tmp))"  grep -q "^0.0" time.tmp; }

which cached-nix-shell > /dev/null || exit 1

trap 'rm -f time.tmp out.tmp' EXIT

run ./00-lua.sh
check_contains "Lua.org"
check_slow

run ./00-lua.sh
check_contains "Lua.org"
check_fast

run ./01-luajit.sh
check_contains "http://luajit.org/"
check_slow

run ./01-luajit.sh
check_contains "http://luajit.org/"
check_fast

run ./02-lua.lua
check_contains "42"
check_fast
