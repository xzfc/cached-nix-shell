{ pkgs ? import <nixpkgs> { } }:
let main = import ./default.nix { inherit pkgs; };
in with pkgs;
mkShell {
  buildInputs = main.buildInputs ++ main.nativeBuildInputs ++ [
    cargo-edit
    niv
    nixfmt
    rustfmt
    shellcheck
    # Required for cargo
    git
    openssh
  ];
  inherit (main) BLAKE3_CSRC;
  CNS_IN_NIX_SHELL = "1";
}
