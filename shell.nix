{ nixpkgs ? import <nixpkgs> {} }:
with nixpkgs;
mkShell {
  buildInputs = [
    niv
    cargo carnix rustfmt
    pkgconfig openssl
  ];
}
