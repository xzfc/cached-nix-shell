#!/bin/sh
. ./lib.sh
# Check that shell options are preserved.
# https://github.com/xzfc/cached-nix-shell/issues/28

run nix-shell --pure -p --run '{ shopt -p; shopt -po; } > tmp/nix-shell'
run cached-nix-shell --pure -p --run '{ shopt -p; shopt -po; } > tmp/cached-nix-shell'
check "Options are the same" diff tmp/nix-shell tmp/cached-nix-shell
rm tmp/nix-shell tmp/cached-nix-shell

run $(nix-shell --pure -p which expect --run 'which expect') << 'EOF'
set timeout 5
log_user 0

spawn nix-shell --pure -p
send "\{ shopt -p; shopt -po; \} > tmp/nix-shell; exit\r"
expect eof

spawn cached-nix-shell --pure -p
send "\{ shopt -p; shopt -po; \} > tmp/cached-nix-shell; exit\r"
expect eof
EOF
check "Options are the same" diff tmp/nix-shell tmp/cached-nix-shell
