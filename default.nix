{ pkgs ? import <nixpkgs> {} }:
let
  cratesIO = pkgs.callPackage ./crates-io.nix {};
  cargo = pkgs.callPackage ./Cargo.nix { inherit cratesIO; };
in cargo.cached_nix_shell {}
