{ nixpkgs ? import <nixpkgs> {} }:
with nixpkgs;
mkShell {
  buildInputs = [ cargo carnix ];
}
