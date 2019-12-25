{ pkgs ? import <nixpkgs> {} }:
let
  cratesIO = pkgs.callPackage ./crates-io.nix {};
  cargo = pkgs.callPackage ./Cargo.nix { inherit cratesIO; };
in (cargo.cached_nix_shell {}).overrideAttrs(a: rec {
  name = "${pname}-${version}";
  pname = "cached-nix-shell";
  version = a.crateVersion;
  buildInputs = [ pkgs.pkgconfig pkgs.openssl ];
  CARGO_USE_OUT = "1";
  postInstall = ''
    # https://github.com/NixOS/nixpkgs/pull/73803
    if [ -d "$lib" ];then mv $lib/* $out; fi

    rm $out/bin/*.d $out/lib/link $out/lib/cached-nix-shell.opt
    rm -r $out/lib/cached-nix-shell

    mkdir -p $out/var/empty
  '';
})
