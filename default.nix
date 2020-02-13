{ pkgs ? import <nixpkgs> { } }:
let
  sources = import ./nix/sources.nix;
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
in (naersk.buildPackage {
  root = gitignoreSource ./.;
  buildInputs = [ pkgs.pkgconfig pkgs.openssl ];
}).overrideAttrs (_: {
  CNS_IN_NIX_BUILD = "1";
  # FIXME: https://github.com/xzfc/cached-nix-shell/issues/2
  # CNS_GIT_COMMIT = pkgs.lib.commitIdFromGitRepo ./.git;
  postInstall = ''
    mkdir -p $out/lib $out/var/empty $out/share/cached-nix-shell
    cp target/release/build/cached-nix-shell-*/out/trace-nix.so $out/lib
    cp rcfile.sh $out/share/cached-nix-shell/rcfile.sh
  '';
})
