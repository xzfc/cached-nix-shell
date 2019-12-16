#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p stdenv

echo ${SOME_VAR-doesnt-have-some-var}
