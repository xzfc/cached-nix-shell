{ stdenv }:
let str = import ./tmp/03-foo.nix;
in stdenv.mkDerivation {
  name = "cached-nix-shell-test";
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    echo 'echo ${str}' > $out/bin/x
    chmod +x $out/bin/x
  '';
}
