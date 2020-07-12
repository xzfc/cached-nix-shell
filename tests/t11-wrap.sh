#!/bin/sh
. ./lib.sh
# Test --wrap

run cached-nix-shell --wrap env nix-shell -p lua --run 'lua -v'
check_contains "Lua.org"
check_slow

run cached-nix-shell --wrap env nix-shell -p lua --run 'lua -v'
check_contains "Lua.org"
check_fast
