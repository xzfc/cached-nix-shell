#!/bin/sh
. ./lib.sh

# Check that changing --run/--exec arguments do not invalidate the cache.
run cached-nix-shell -p lua --run 'lua -v'
check_contains "Lua.org"
check_slow

run cached-nix-shell -p lua --run 'lua -v | rev'
check_contains "gro.auL"
check_fast

run cached-nix-shell -p luajit --run 'lua -v'
check_contains "https\?://luajit.org/"
check_slow

run cached-nix-shell -p luajit --exec lua -v
check_contains "https\?://luajit.org/"
check_fast


# Check argument expanding "-pj16" -> "-p -j 16"
run cached-nix-shell -pj16 luajit --exec lua -v
check_contains "https\?://luajit.org/"
check_fast


# Check -v/--verbose.
# This test produces a lot of output, so, pipe it through `tail`
run cached-nix-shell -vp --run : | tail -n3
check_slow
check_stderr_contains "^evaluating file '/"

run cached-nix-shell -vp --run :
check_fast


# Check shebang argument passing.
run_inline a b c << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i bash -p

printf "count=%s" "$#"
printf " '%s'" "$@"
printf "\n"
EOF
check_contains "^count=3 'a' 'b' 'c'$"


# Check nontrivial interpreter.
run_inline a 'b c' << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i "printf ', %q' {1..3}" -p
EOF
check_contains "^, 1, 2, 3, \./tmp/inline[0-9]\+, a, 'b c'$"
