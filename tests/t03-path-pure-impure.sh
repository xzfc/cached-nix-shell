#!/bin/sh
. ./lib.sh

mkdir -p tmp/bin

put +x tmp/bin/some_bin << 'EOF'
#!/bin/sh
echo running-some-bin
EOF

export PATH=$PWD/tmp/bin:$PATH


run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p hello

if command -v some_bin >/dev/null 2>&1; then
	some_bin
else
	echo cant-find-some-bin
fi
hello
EOF
check_contains "running-some-bin"
check_contains "Hello, world!"


run_inline << 'EOF'
#!/usr/bin/env cached-nix-shell
#! nix-shell -i sh -p hello --pure

if command -v some_bin >/dev/null 2>&1; then
	some_bin
else
	echo cant-find-some-bin
fi
hello
EOF
check_contains "cant-find-some-bin"
check_contains "Hello, world!"
