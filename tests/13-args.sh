#!/usr/bin/env cached-nix-shell
#! nix-shell -i bash -p

printf "count=%s" "$#"
printf " '%s'" "$@"
printf "\n"
