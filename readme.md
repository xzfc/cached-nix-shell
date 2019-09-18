# cached-nix-shell


## Problem

https://discourse.nixos.org/t/speeding-up-nix-shell-shebang/4048

Having a single file contains both code and its dependencies is a useful feature provided by nix-shell. However long startup times make it unsuitable for some use-cases.

This example script took 0.5 seconds to run on my machine:

```
#! /usr/bin/env nix-shell
#! nix-shell -i python -p python

print "Hello world!"
```

Scripts with more dependencies can take a couple of seconds just to set up the environment.


## Installtion

Clone the repository and run `nix-env -i -f default.nix`.

## Usage

Just replace `nix-shell` with `cached-nix-shell` in the shebang line:

```sh
#! /usr/bin/env cached-nix-shell
#! nix-shell -i python -p python

print "Hello world!"
```

```sh
$ time ./test.py # first run; no cache used
...
$ time ./test.py
...
```

Alternatively, call `cached-nix-shell` directly:

```
cached-nix-shell ./test.py
```

## Caveats

Cache could be staled in following situations:

* Access to external files: `#! nix-shell -p "import ./foo.nix"`
* Probably there is more

## License

This project is dual-licensed under the [Unlicense](https://unlicense.org) and MIT licenses.

You may use this code under the terms of either license.
