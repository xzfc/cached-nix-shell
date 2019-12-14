{ pkgs ? import <nixpkgs> {} }:
let
  cratesIO = pkgs.callPackage ./crates-io.nix {};
  cargo = pkgs.callPackage ./Cargo.nix { inherit cratesIO; };
  crate = cargo.cached_nix_shell {};
in pkgs.stdenv.mkDerivation {
  name = "cached-nix-shell";
  srcs = ./nix-trace;

  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp ${crate}/bin/cached-nix-shell $out/bin
    cp build/trace-nix.so $out/lib
  '';
}
