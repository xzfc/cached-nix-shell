{
  pkgs ? import <nixpkgs> { },
}:
let
  main = import ./default.nix { inherit pkgs; };
in
pkgs.mkShell {
  buildInputs =
    main.buildInputs
    ++ main.nativeBuildInputs
    ++ [
      pkgs.cargo-edit
      pkgs.clang-tools
      pkgs.clippy
      pkgs.niv
      pkgs.nixfmt-rfc-style
      pkgs.rust-analyzer
      pkgs.rustc
      pkgs.rustfmt
      pkgs.shellcheck
      # Required for cargo
      pkgs.git
      pkgs.openssh
    ];
  inherit (main) BLAKE3_CSRC;
  CNS_IN_NIX_SHELL = "1";
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}
