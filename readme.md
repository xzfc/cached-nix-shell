# cached-nix-shell


## Problem

Having a single file containing both code and its dependencies is a useful feature provided by `nix-shell`. However long startup times make it unsuitable for some use-cases.

This example script took 0.5 seconds to run on my machine:

```python
#! /usr/bin/env nix-shell
#! nix-shell -i python -p python
print "Hello world!"
```

Scripts with more dependencies can take a couple of seconds just to set up the environment.

## Solution

`cached-nix-shell` stores environment variables set up by `nix-shell` and reuses them on subsequent runs.
It [traces](./nix-trace) which files are read by `nix` during an evaluation, and performs a proper cache invalidation if any of the used files are changed.
The cache is stored in `~/.cache/cached-nix-shell/`.

## Installation

```sh
nix-env -i -f https://github.com/xzfc/cached-nix-shell/tarball/master
```

## Usage

Just replace `nix-shell` with `cached-nix-shell` in the shebang line:

```python
#! /usr/bin/env cached-nix-shell
#! nix-shell -i python -p python
print "Hello world!"
```

```
$ time ./hello.py # first run; no cache used
cached-nix-shell: updating cache
Hello world!
./hello.py  0.34s user 0.07s system 91% cpu 0.458 total
$ time ./hello.py
Hello world!
./hello.py  0.02s user 0.01s system 95% cpu 0.033 total
```

Alternatively, call `cached-nix-shell` directly:

```sh
cached-nix-shell ./test.py
```

## Cache invalidation

The following situations are covered:

* `builtins.readFile` is used
* `builtins.readDir` is used
* `import ./file.nix` is used
* updating `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`
* updating nix channels
* updating `$NIX_PATH` environment variable

The following situations aren't handled by `cached-nix-shell` and may lead to staled cache:

* `builtins.fetchurl` is used (e.g. in [nixpkgs-mozilla])

[nixpkgs-mozilla]: https://github.com/mozilla/nixpkgs-mozilla

## Related

* https://discourse.nixos.org/t/speeding-up-nix-shell-shebang/4048
* [lorri](https://github.com/target/lorri), a `nix-shell` replacement for project development
  * [lorri #167](https://github.com/target/lorri/issues/167)

## License

This project is dual-licensed under the [Unlicense](https://unlicense.org) and MIT licenses.

You may use this code under the terms of either license.
