[ "$IN_NIX_SHELL" = impure ] && [ -n "$PS1" ] && [ -e ~/.bashrc ] && source ~/.bashrc
[ -n "$PS1" -a -z "$NIX_SHELL_PRESERVE_PROMPT" ] && PS1='\n\[\033[1;32m\][cached-nix-shell:\w]\$\[\033[0m\] '
