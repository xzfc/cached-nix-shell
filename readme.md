# cached-nix-shell
[![Build Status](https://img.shields.io/github/workflow/status/xzfc/cached-nix-shell/Test/master?logo=github)](https://github.com/xzfc/cached-nix-shell/actions?query=workflow%3ATest+branch%3Amaster)
![License](https://img.shields.io/badge/license-Unlicense%20OR%20MIT-blue)
[![Nixpkgs unstable package](https://repology.org/badge/version-for-repo/nix_unstable/cached-nix-shell.svg)](https://nixos.org/nixos/packages.html?attr=cached-nix-shell&channel=nixpkgs-unstable&query=cached-nix-shell)

`cached-nix-shell` is a caching layer for `nix-shell` featuring instant startup time on subsequent runs.

It supports NixOS and Linux.

## Installation

Install the release version from Nixpkgs:
```sh
nix-env -iA nixpkgs.cached-nix-shell
```

Or, install the latest development version from GitHub:
```sh
nix-env -if https://github.com/xzfc/cached-nix-shell/tarball/master
```

## Usage

Just replace `nix-shell` with `cached-nix-shell` in the shebang line:

```python
#! /usr/bin/env cached-nix-shell
#! nix-shell -i python3 -p python
print("Hello, World!")
```

Alternatively, call `cached-nix-shell` directly:

```sh
$ cached-nix-shell ./hello.py
$ cached-nix-shell -p python3 --run 'python --version'
```

Or use the `--wrap` option for programs that call `nix-shell` internally.

```sh
$ cached-nix-shell --wrap stack build
```

## Performance

```
$ time ./hello.py # first run; no cache used
cached-nix-shell: updating cache
Hello, World!
./hello.py  0.33s user 0.06s system 91% cpu 0.435 total
$ time ./hello.py
Hello, World!
./hello.py  0.02s user 0.01s system 97% cpu 0.029 total
```

## Caching and cache invalidation

`cached-nix-shell` stores environment variables set up by `nix-shell` and reuses them on subsequent runs.
It [traces](./nix-trace) which files are read by `nix` during an evaluation, and performs a proper cache invalidation if any of the used files are changed.
The cache is stored in `~/.cache/cached-nix-shell/`.

The following situations are covered:

* `builtins.readFile` is used
* `builtins.readDir` is used
* `import ./file.nix` is used
* updating `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`
* updating nix channels
* updating `$NIX_PATH` environment variable

The following situations aren't handled by `cached-nix-shell` and may lead to staled cache:

* `builtins.fetchurl` or other network builtins are used (e.g. in [nixpkgs-mozilla])

[nixpkgs-mozilla]: https://github.com/mozilla/nixpkgs-mozilla

## Related

* https://discourse.nixos.org/t/speeding-up-nix-shell-shebang/4048
* There are related projects focused on using `nix-shell` for project developing:
  * [direnv](https://direnv.net/) with [use_nix](https://github.com/direnv/direnv/wiki/Nix)
  * [Cached and Persistent Nix shell with direnv integration](https://gist.github.com/mbbx6spp/731076cb8fc620b064b8e5b28fb1c796)
  * [lorri](https://github.com/target/lorri), a `nix-shell` replacement for project development
    * [lorri #167](https://github.com/target/lorri/issues/167)
  * [nix-develop](https://gitlab.com/mightybyte/nix-develop), universal build tool featuring cached `nd shell` command

* [https://github.com/rycee/home-manager/issues/447](https://github.com/rycee/home-manager/issues/447)
