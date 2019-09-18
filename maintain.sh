#!/bin/sh

case $1 in
carnix)
	carnix generate-nix --src ./.
	rm -f crates-io.list
	;;
install) nix-env -i -f default.nix ;;
*) exit 1;
esac
