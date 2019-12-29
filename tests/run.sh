#!/bin/sh

cd "$(dirname -- $0)"
rm -rf tmp
mkdir -p tmp
rm -rf ~/.cache/cached-nix-shell

run() {
	rm -f tmp/time tmp/out
	printf "\33[1mRunning %s\33[m\n" "$*"
	time -o tmp/time -f "%e" -- "$@" > tmp/out
}

check() {
	local text
	text=$1
	shift
	if "$@";then
		printf "\33[32m+ %s\33[m\n" "$text"
	else
		printf "\33[31m- %s\33[m\n" "$text"
		result=1
	fi
}

check_contains() { check "contains $1"   grep -q "$1" tmp/out; }
check_slow() { check "slow ($(cat tmp/time))"  grep -vq "^0.0" tmp/time; }
check_fast() { check "fast ($(cat tmp/time))"  grep -q "^0.0" tmp/time; }

skip() { printf "\33[33m? skip %s\33[m\n" "$*"; }

which cached-nix-shell time grep > /dev/null || exit 1

trap 'rm -rf tmp' EXIT
result=0

export PATH=$PWD/bin:$PATH
export SOME_VAR=some-var-value
export LC_ALL=C

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

echo '"val1"' > ./tmp/03-foo.nix
run ./03-file-dep.sh
check_contains "val1"
check_slow

run ./03-file-dep.sh
check_contains "val1"
check_fast

echo '"val2"' > ./tmp/03-foo.nix
run ./03-file-dep.sh
check_contains "val2"
check_slow

run ./04-path-impure.sh
check_contains "running-some-bin"
check_contains "Hello, world!"

run ./05-path-pure.sh
check_contains "cant-find-some-bin"

run ./06-env-impure.sh
check_contains "some-var-value"

run ./07-env-pure.sh
check_contains "doesnt-have-some-var"

run ./08-with_-I.lua
check_contains "aGVsbG8="

run ./09-without_--packages.sh
check_contains "Lua.org"

run cached-nix-shell 09-lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run cached-nix-shell ./09-lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run env --chdir .. cached-nix-shell tests/09-lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run ./10-with_--attr.sh
check_contains "i-am-foo"
check_contains "cant-find-bar"

run cached-nix-shell -p lua --run 'lua -v'
check_contains "Lua.org"
check_slow

run cached-nix-shell -p lua --run 'lua -v | rev'
check_contains "gro.auL"
check_fast

run cached-nix-shell -p luajit --run 'lua -v'
check_contains "http://luajit.org/"
check_slow

run cached-nix-shell -p luajit --exec lua -v
check_contains "http://luajit.org/"
check_fast

exit $result
