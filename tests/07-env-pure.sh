#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p stdenv --pure

echo ${SOME_VAR-doesnt-have-some-var}
