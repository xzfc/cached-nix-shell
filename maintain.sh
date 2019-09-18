#!/bin/sh

case $1 in
carnix)
	carnix generate-nix --src ./.
	rm -f crates-io.list
	;;
install)
	rm -f result
	nix-env -i -f default.nix
	;;
build-nix)
	rm -f result
	nix-build default.nix
	;;
test)
	./tests/run.sh
	;;
*) exit 1;
esac
