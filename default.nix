{ pkgs ? import <nixpkgs> { } }:
let
  sources = import ./nix/sources.nix;
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
  blake3-src = sources.BLAKE3;
in (naersk.buildPackage {
  root = gitignoreSource ./.;
  buildInputs = [ pkgs.openssl pkgs.ronn ];
}).overrideAttrs (_: {
  CNS_GIT_COMMIT = if builtins.pathExists ./.git then
    pkgs.lib.commitIdFromGitRepo ./.git
  else
    "next";
  BLAKE3_CSRC = "${blake3-src}/c";
  postBuild = ''
    ronn -r cached-nix-shell.1.md
  '';
  postInstall = ''
    mkdir -p $out/lib
    cp target/release/build/cached-nix-shell-*/out/trace-nix.so $out/lib/

    mkdir -p $out/share/cached-nix-shell
    cp rcfile.sh $out/share/cached-nix-shell/

    mkdir -p $out/share/man/man1
    cp cached-nix-shell.1 $out/share/man/man1/

    mkdir -p $out/libexec/cached-nix-shell
    ln -s $out/bin/cached-nix-shell $out/libexec/cached-nix-shell/nix-shell

    mkdir -p $out/var/empty
  '';
})
