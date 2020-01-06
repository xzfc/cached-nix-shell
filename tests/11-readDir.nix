with import <nixpkgs> {};
mkShell {
  x = builtins.toJSON (builtins.readDir ./tmp/dir);
}
