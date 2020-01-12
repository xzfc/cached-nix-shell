#!/bin/sh

case $1 in
install)
	nix-env -i -f default.nix
	;;
build-nix)
	nix-build default.nix
	;;
test)
	cargo test &&
	./tests/run.sh &&
	make -C ./nix-trace test &&
	echo ok
	;;
*) exit 1;
esac
