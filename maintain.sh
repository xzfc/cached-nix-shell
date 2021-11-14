#!/usr/bin/env bash
trap rc=1 ERR; rc=0; case $1 in ################################################
################################################################################

''install)
	nix-env -i -f default.nix

;;build-nix)
	nix-build default.nix

;;format)
	nixfmt default.nix shell.nix
	cargo fmt

;;update)
	cargo upgrade
	cargo update
	cargo update -p remove_dir_all --precise 0.5.2 # 0.5.3 bumps MSRV
	cargo update -p subtle --precise 2.2.3 # 2.3.0 bumps MSRV
	niv update

;;lint)
	cd tests/ && shellcheck *.sh

;;test)
	cargo test
	./tests/run.sh
	make -C ./nix-trace test

################################################################################
;;*) cat $0; rc=1; esac; exit $rc ##############################################
