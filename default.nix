{ pkgs ? import <nixpkgs> { } }:
let
  sources = import ./nix/sources.nix;
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
  blake3-src = pkgs.fetchFromGitHub {
    owner = "BLAKE3-team";
    repo = "BLAKE3";
    rev = "c-0.2.2";
    sha256 = "1xsh8hf3xmi42h6aszgn58kwrrc1s7rpximil3k1gzq7878fw3bc";
  };
in (naersk.buildPackage {
  root = gitignoreSource ./.;
  buildInputs = [ pkgs.openssl pkgs.ronn ];
}).overrideAttrs (_: {
  CNS_IN_NIX_BUILD = "1";
  # FIXME: https://github.com/xzfc/cached-nix-shell/issues/2
  # CNS_GIT_COMMIT = pkgs.lib.commitIdFromGitRepo ./.git;
  BLAKE3_CSRC = "${blake3-src}/c";
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
