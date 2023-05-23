#!/bin/sh
. ./lib.sh

put ./tmp/foo << 'EOF'
with import <nixpkgs> { };
mkShell { VAR="val"; }
EOF

put ./tmp/empty << 'EOF'
{}
EOF

# Get default NIX_PATH in case it's not set. Do not export it to not interfere
# with tests that do not use it.
[ "${NIX_PATH:-}" ] || NIX_PATH="$(
	nix-instantiate --eval -E '
		builtins.concatStringsSep ":"
		(map (a: (if a.prefix == "" then "" else a.prefix + "=") + a.path)
		builtins.nixPath)
	' | tr -d '"')"

################################################################################
# <path_variable>
################################################################################

# <path_variable>, absolute NIX_PATH

run            env "NIX_PATH=$PWD/tmp:$NIX_PATH"         cached-nix-shell '<foo>' --run 'echo $VAR'
check_contains "^val$"
check_slow

run --chdir .. env "NIX_PATH=$PWD/tmp:$NIX_PATH"         cached-nix-shell '<foo>' --run 'echo $VAR'
check_contains "^val$"
check_fast

run            env "NIX_PATH=bar=$PWD/tmp/foo:$NIX_PATH" cached-nix-shell '<bar>' --run 'echo $VAR'
check_contains "^val$"
check_slow

run --chdir .. env "NIX_PATH=bar=$PWD/tmp/foo:$NIX_PATH" cached-nix-shell '<bar>' --run 'echo $VAR'
check_contains "^val$"
check_fast

# <path_variable>, absolute -I

run            cached-nix-shell -I "$PWD/tmp"         '<foo>' --run 'echo $VAR'
check_contains "^val$"
check_slow

run --chdir .. cached-nix-shell -I "$PWD/tmp"         '<foo>' --run 'echo $VAR'
check_contains "^val$"
check_fast

run            cached-nix-shell -I "bar=$PWD/tmp/foo" '<bar>' --run 'echo $VAR'
check_contains "^val$"
check_slow

run --chdir .. cached-nix-shell -I "bar=$PWD/tmp/foo" '<bar>' --run 'echo $VAR'
check_contains "^val$"
check_fast

# <path_variable>, relative NIX_PATH

run env "NIX_PATH=.:$NIX_PATH"         cached-nix-shell '<tmp/foo>' --run 'echo $VAR'
check_contains "^val$"

run env "NIX_PATH=bar=./tmp:$NIX_PATH" cached-nix-shell '<bar/foo>' --run 'echo $VAR'
check_contains "^val$"

# <path_variable>, relative -I

run cached-nix-shell -I .             '<tmp/foo>' --run 'echo $VAR'
check_contains "^val$"

run cached-nix-shell -I bar=./tmp/foo '<bar>'     --run 'echo $VAR'
check_contains "^val$"

################################################################################
# Other cases
################################################################################

# URI
run cached-nix-shell https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz -A lua --run 'env'
check_contains '^name=lua-5\..*'

# Multiple .nix files (why it is even supported by nix-shell)

run cached-nix-shell ./tmp/foo ./tmp/empty --run 'echo $VAR'
check_contains "^val$"

run cached-nix-shell ./tmp/empty ./tmp/foo --run 'echo $VAR'
check_contains "^val$"

# Path to .drv file

lua_drv=$(nix-instantiate --no-gc-warning -E '(import <nixpkgs> {}).lua')

run cached-nix-shell "$lua_drv" --run 'env'
check_contains '^name=lua-5\..*'

# TODO: `nix-shell /nix/store/*.drv!out` is not implemented yet.
# run cached-nix-shell "$lua_drv!out" --run 'env'
# check_contains '^name=lua-5\..*'
