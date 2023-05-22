#!/bin/sh

set -e

# Check prerequisites
hash cached-nix-shell cat chmod cmp cp \
	date diff env grep ln mkdir rev rm tail tee time touch

trap 'exit 130' INT

case "$0" in
  */*) cd -- "${0%/*}";;
esac

echo "Testing $(command -v cached-nix-shell)"

result=0

if [ $# = 0 ]; then
	set -- ./t[0-9]*.sh
fi

for t in "$@"; do
	sh -- "$t" || result=1
done

if [ "$result" = 0 ]; then
	printf "\n\33[32mAll tests passed\33[m\n"
else
	printf "\n\33[31mSome tests failed\33[m\n"
fi
rm -rf tmp
exit $result
