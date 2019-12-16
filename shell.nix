{ nixpkgs ? import <nixpkgs> {} }:
with nixpkgs;
mkShell {
  buildInputs = [
    cargo carnix rustfmt
    pkgconfig openssl
  ];
}
