#!/bin/sh
. ./lib.sh

put +x ./tmp/lua.sh << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p lua

lua -v
EOF

put +x ./tmp/luajit.sh << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p luajit

lua -v
EOF

put +x ./tmp/lua.lua << 'EOF'
#! /usr/bin/env cached-nix-shell
--[[
#! nix-shell -i lua -p lua
]]

print(6 * 7)
EOF


run ./tmp/lua.sh
check_contains "Lua.org"
check_slow

run ./tmp/lua.sh
check_contains "Lua.org"
check_fast

run ./tmp/luajit.sh
check_contains "http://luajit.org/"
check_slow

run ./tmp/luajit.sh
check_contains "http://luajit.org/"
check_fast

run ./tmp/lua.lua
check_contains "42"
check_fast



# Check various paths to use the same .nix file.
put +x ./tmp/lua.nix << 'EOF'
with import <nixpkgs> { }; mkShell { buildInputs = [ lua ]; }
EOF

run_inline << 'EOF'
#! /usr/bin/env cached-nix-shell
#! nix-shell -i sh ./lua.nix
lua -v
EOF
check_contains "Lua.org"

run cached-nix-shell ./tmp/lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run env --chdir tmp cached-nix-shell ./lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run env --chdir tmp cached-nix-shell lua.nix --run 'lua -v'
check_contains "Lua.org"
check_fast

run env --chdir / cached-nix-shell "$PWD/tmp/lua.nix" --run 'lua -v'
check_contains "Lua.org"
check_fast
