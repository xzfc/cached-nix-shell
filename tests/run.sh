#!/bin/sh

cd "$(dirname -- $0)"
rm -rf tmp
mkdir -p tmp tmp/cache
export XDG_CACHE_HOME=$PWD/tmp/cache

run() {
	rm -f tmp/time tmp/out tmp/err
	printf "\33[33m* Running %s\33[m\n" "$*"
	time -o tmp/time -f "%e" -- "$@" 2>&1 > tmp/out | tee tmp/err
}

not() {
	! "$@"
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

check_contains() { check "contains $1" grep -q "$1" tmp/out; }
check_stderr_contains() { check "contains $1" grep -q "$1" tmp/err; }
check_slow() {
	check "slow ($(cat tmp/time))" \
		grep -q "^cached-nix-shell: updating cache$" tmp/err
}
check_fast() {
	check "fast ($(cat tmp/time))" \
		not grep -q "^cached-nix-shell: updating cache$" tmp/err
}

skip() { printf "\33[33m? skip %s\33[m\n" "$*"; }

which cached-nix-shell time grep tee > /dev/null || exit 1

echo "Testing $(which cached-nix-shell)"

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

mkdir -p tmp/dir/a
ln -s c tmp/dir/b
touch tmp/dir/c
run cached-nix-shell ./11-readDir.nix --run 'echo $x'
check_contains '{"a":"directory","b":"symlink","c":"regular"}'
check_slow

run cached-nix-shell ./11-readDir.nix --run 'echo $x'
check_contains '{"a":"directory","b":"symlink","c":"regular"}'
check_fast

rm tmp/dir/b
touch tmp/dir/b
run cached-nix-shell ./11-readDir.nix --run 'echo $x'
check_contains '{"a":"directory","b":"regular","c":"regular"}'
check_slow

run cached-nix-shell ./12-implicit-default-nix --run 'lua -v'
check_contains "Lua.org"

# dir <-> file cache invalidation {{{
mkdir -p ./tmp/implicit/f
cp ./12-implicit-default-nix/default.nix ./tmp/implicit/f/default.nix
run cached-nix-shell ./tmp/implicit/f --run 'lua -v'
check_contains "Lua.org"
check_slow

rm -rf ./tmp/implicit/f
cp ./12-implicit-default-nix/default.nix ./tmp/implicit/f
run cached-nix-shell ./tmp/implicit/f --run 'lua -v'
check_contains "Lua.org"
check_slow

rm -f ./tmp/implicit/f
mkdir -p ./tmp/implicit/f
cp ./12-implicit-default-nix/default.nix ./tmp/implicit/f/default.nix
run cached-nix-shell ./tmp/implicit/f --run 'lua -v'
check_contains "Lua.org"
check_slow
# }}}

run ./13-args.sh a b c
check_contains "^count=3 'a' 'b' 'c'$"

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

run cached-nix-shell -pj16 luajit --exec lua -v
check_contains "http://luajit.org/"
check_fast

run cached-nix-shell -vp --run :
check_slow
check_stderr_contains "^evaluating file '/"

run cached-nix-shell -vp --run :
check_fast

exit $result
