#!/bin/sh
. ./lib.sh
# Test -A / --attr handling

put ./tmp/foobar.nix << 'EOF'
with import <nixpkgs> { }; {
  foo = mkShell {
    buildInputs = [
      (stdenv.mkDerivation {
        name = "cached-nix-shell-test-foo";
        unpackPhase = ":";
        installPhase = ''
          mkdir -p $out/bin
          echo 'echo i-am-foo' > $out/bin/foo
          chmod +x $out/bin/foo
        '';
      })
    ];
  };
  bar = mkShell {
    buildInputs = [
      (stdenv.mkDerivation {
        name = "cached-nix-shell-test-bar";
        unpackPhase = ":";
        installPhase = ''
          mkdir -p $out/bin
          echo 'echo i-am-bar' > $out/bin/bar
          chmod +x $out/bin/bar
        '';
      })
    ];
  };
}
EOF


run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -A foo ./foobar.nix

if command -v foo >/dev/null 2>&1; then
	foo
else
	echo cant-find-foo
fi

if command -v bar >/dev/null 2>&1; then
	bar
else
	echo cant-find-bar
fi
EOF
check_contains "i-am-foo"
check_contains "cant-find-bar"
