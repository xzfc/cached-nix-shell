#!/bin/sh
. ./lib.sh
# Check that shell options are preserved.
# https://github.com/xzfc/cached-nix-shell/issues/28

run nix-shell --pure -p --run '{ shopt -p; shopt -po; } > tmp/nix-shell'
run cached-nix-shell --pure -p --run '{ shopt -p; shopt -po; } > tmp/cached-nix-shell'
check "Options are the same" diff tmp/nix-shell tmp/cached-nix-shell
