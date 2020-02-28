{ pkgs ? import <nixpkgs> { } }:
let
  sources = import ./nix/sources.nix;
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
in (naersk.buildPackage {
  root = gitignoreSource ./.;
  buildInputs = [ pkgs.openssl pkgs.ronn ];
}).overrideAttrs (_: {
  CNS_IN_NIX_BUILD = "1";
  # FIXME: https://github.com/xzfc/cached-nix-shell/issues/2
  # CNS_GIT_COMMIT = pkgs.lib.commitIdFromGitRepo ./.git;
  postBuild = ''
    ronn -r cached-nix-shell.1.md
  '';
  postInstall = ''
    mkdir -p $out/lib $out/share/cached-nix-shell $out/share/man/man1 $out/var/empty
    cp target/release/build/cached-nix-shell-*/out/trace-nix.so $out/lib
    cp rcfile.sh $out/share/cached-nix-shell/rcfile.sh
    cp cached-nix-shell.1 $out/share/man/man1
  '';
})
