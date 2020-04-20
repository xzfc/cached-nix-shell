#!/bin/sh
. ./lib.sh

export SOME_VAR=some-var-value

run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p

echo ${SOME_VAR-doesnt-have-some-var}
EOF
check_contains "some-var-value"

run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p --pure

echo ${SOME_VAR-doesnt-have-some-var}
EOF
check_contains "doesnt-have-some-var"
