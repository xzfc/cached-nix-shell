with import <nixpkgs> {};
{
  foo = mkShell {
    buildInputs = [(
      stdenv.mkDerivation {
        name = "cached-nix-shell-test-foo";
        unpackPhase = ":";
        installPhase = ''
          mkdir -p $out/bin
          echo 'echo i-am-foo' > $out/bin/foo
          chmod +x $out/bin/foo
        '';
      }
    )];
  };
  bar = mkShell {
    buildInputs = [(
      stdenv.mkDerivation {
        name = "cached-nix-shell-test-bar";
        unpackPhase = ":";
        installPhase = ''
          mkdir -p $out/bin
          echo 'echo i-am-bar' > $out/bin/bar
          chmod +x $out/bin/bar
        '';
      }
    )];
  };
}
