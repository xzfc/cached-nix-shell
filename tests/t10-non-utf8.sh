#!/bin/sh
. ./lib.sh

unset F0 F1
F0="$(printf '%b' '\360')"
F1="$(printf '%b' '\361')"


# Non-utf8 PWD
mkdir ./tmp/a"$F0"b
put ./tmp/a"$F0"b/shell.nix << 'EOF'
with import <nixpkgs> { }; mkShell { buildInputs = [ lua ]; }
EOF

put +x ./tmp/a"$F0"b/run.sh << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh --pure ./shell.nix
lua -v
EOF

run cached-nix-shell ./tmp/a"$F0"b/run.sh
check_contains "Lua.org"


# Non-utf8 environment variable passed to shebang script
export VAR=a"$F0"b
run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -pi sh
env -0 | LANG=C grep -z "^VAR=" | cat -v
EOF
check_contains '^VAR=aM-pb\^@$'
unset VAR


# Non-utf8 shebang script
run_inline << EOF # unquoted
#!/usr/bin/env cached-nix-shell
#! nix-shell -pi sh
echo '$F0$F1' | cat -v
EOF
check_contains '^M-pM-q$'


# Non-utf8 shebang script argument
run_inline foo"$F0"bar << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -pi sh
printf "!%s!\n" "$@" | cat -v
EOF
check_contains "^!fooM-pbar!$"


# Non-utf8 environment variable passed to/exported by setup.sh
export VAR_IN=a"$F0"b
put ./tmp/shellhook.nix << 'EOF'
with import <nixpkgs> { };
mkShell {
  shellHook = ''
    export VAR_OUT
    VAR_OUT=out:$(env -0 | LANG=C grep -z "^VAR_IN=" | cat -v)
  '';
}
EOF
run cached-nix-shell ./tmp/shellhook.nix --pure --keep VAR_IN \
	--run 'printf "%s\n" "$VAR_OUT"'
check_contains '^out:VAR_IN=aM-pb\^@$'
unset VAR_IN
