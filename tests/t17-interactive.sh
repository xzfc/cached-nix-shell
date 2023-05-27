#!/bin/sh
. ./lib.sh
# Test interactive shell

unset PS1 BASHRC_IS_SOURCED NIX_SHELL_PRESERVE_PROMPT

expect=$(nix-shell --pure -p which expect --run 'which expect')
put +x tmp/run << EOF
# Make sure that prompt containing long PWD will fit
set stty_init "rows 10 cols 2000"
# TODO: fix test not to download nixpkgs when running on CI
set timeout 180 ;

log_file -a tmp/out
log_user 0
spawn sh -c [lindex \$argv 0]
send [string map {"\n" "\r\n"} [read stdin]]
send "exit\r"
expect eof
log_file
exec sh -c "tr -d \"\\r\" < tmp/out > tmp/err"
EOF

mkdir -p tmp/home
export HOME=$PWD/tmp/home
put tmp/home/.bashrc << 'EOF'
PS1=NEW_PROMPT
BASHRC_IS_SOURCED=1
EOF

run $expect tmp/run 'sleep 0.1 && cached-nix-shell --pure -p' << 'EOF'
echo uryyb jbeyq | tr a-z n-za-m
EOF
check_contains '\[cached-nix-shell:'
check_contains 'hello world'
check_slow

run $expect tmp/run 'cached-nix-shell --pure -p' << 'EOF'
echo uryyb jbeyq | tr a-z n-za-m
EOF
check_contains 'hello world'
skip check_fast  # TODO: fix /tmp/nix-$$-* issue

run cached-nix-shell --pure -p --exec true
check_fast


# Check pre-defined env vars and inclusion of .bashrc
run $expect tmp/run 'cached-nix-shell --pure -p' << 'EOF'
echo IN_NIX_SHELL=$IN_NIX_SHELL
echo IN_CACHED_NIX_SHELL=$IN_CACHED_NIX_SHELL
echo BASHRC_IS_SOURCED=${BASHRC_IS_SOURCED:-unset}
echo PS1=$PS1
EOF
check_contains 'IN_NIX_SHELL=pure'
check_contains 'IN_CACHED_NIX_SHELL=1'
check_contains 'BASHRC_IS_SOURCED=unset'
check_contains 'PS1=.*\[cached-nix-shell:\\w].*'
check_fast

run $expect tmp/run 'cached-nix-shell -p' << 'EOF'
echo IN_NIX_SHELL=$IN_NIX_SHELL
echo IN_CACHED_NIX_SHELL=$IN_CACHED_NIX_SHELL
echo BASHRC_IS_SOURCED=${BASHRC_IS_SOURCED:-unset}
echo PS1=$PS1
EOF
check_contains 'IN_NIX_SHELL=impure'
check_contains 'IN_CACHED_NIX_SHELL=1'
check_contains 'BASHRC_IS_SOURCED=1'
check_contains 'PS1=.*\[cached-nix-shell:\\w].*'
check_fast

NIX_SHELL_PRESERVE_PROMPT=1 run $expect tmp/run 'cached-nix-shell -p' << 'EOF'
echo PS1=$PS1
EOF
check_contains 'PS1=NEW_PROMPT'
check_fast
