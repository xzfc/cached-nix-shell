#!/bin/sh

rc=0

case $1 in
install)
	nix-env -i -f default.nix
	;;
build-nix)
	nix-build default.nix
	;;
format)
	nixfmt default.nix shell.nix
	cargo fmt
	;;
update)
	cargo upgrade || rc=1
	cargo update || rc=1
	niv update || rc=1
	;;
test)
	cargo test &&
	./tests/run.sh &&
	make -C ./nix-trace test &&
	echo ok
	;;
*) exit 1;
esac

exit $rc
