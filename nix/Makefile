no-default-target: ; @false

VERSION := $(shell sed < Cargo.toml -n 's/^version *= *"\(.*\)".*/\1/p')

post-build:
	ronn --organization="cached-nix-shell ${VERSION}" -r cached-nix-shell.1.md

post-install:
	mkdir -p ${out}/lib
	cp target/release/build/cached-nix-shell-*/out/trace-nix.so ${out}/lib/
	
	mkdir -p ${out}/share/cached-nix-shell
	cp rcfile.sh ${out}/share/cached-nix-shell/
	
	mkdir -p ${out}/share/man/man1
	cp cached-nix-shell.1 ${out}/share/man/man1/
	
	mkdir -p ${out}/libexec/cached-nix-shell
	ln -s ${out}/bin/cached-nix-shell ${out}/libexec/cached-nix-shell/nix-shell
	
	mkdir -p ${out}/var/empty

.PHONY: no-default-target post-build post-install
