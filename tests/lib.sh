set -e

export XDG_CACHE_HOME=$PWD/tmp/cache
rm -rf ./tmp
mkdir -p ./tmp

printf "\n\33[1m* Test file %s\33[m\n" "$0"

trap 'at_exit $?' EXIT
begin_t=$(date +%s)

at_exit() {
	local rc=$(($? || result))
	local end_t
	end_t=$(date +%s)
	set -- tmp/cache/cached-nix-shell/*.env
	printf "\33[1m* rc:%s seconds:%s entries:%s\33[m\n" \
		"$rc" "$((end_t - begin_t))" "$#"
	exit "$rc"
}

result=0

put() {
	if [ "$#" = 1 ]; then
		cat > "$1"
	elif [ "$#" = 2 ] && [ "$1" = "+x" ]; then
		cat > "$2"
		chmod +x "$2"
	fi
}

run() {
	rm -f tmp/time tmp/out tmp/err
	printf "\33[33m  * Running %s\33[m\n" "$*"
	command time -o tmp/time -f "%e" -- "$@" 2>&1 > tmp/out | tee tmp/err
}

inline=0
run_inline() {
	put +x ./tmp/inline$inline
	run ./tmp/inline$inline "$@"
	inline=$((inline+1))
}

not() {
	! "$@"
}

check() {
	local text
	text=$1
	shift
	if "$@";then
		printf "\33[32m  + %s\33[m\n" "$text"
	else
		printf "\33[31m  - %s\33[m\n" "$text"
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
