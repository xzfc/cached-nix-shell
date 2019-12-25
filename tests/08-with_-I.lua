#! /usr/bin/env cached-nix-shell
--[[
#! nix-shell -i lua -p "luajit.withPackages (p: [ p.basexx ] )"
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-19.09.tar.gz
--]]

print(require("basexx").to_base64("hello"))
