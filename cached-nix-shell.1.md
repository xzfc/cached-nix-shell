# cached-nix-shell - instant startup time for nix-shell(1)

## SYNOPSIS

`cached-nix-shell [`_options_`]...`<br>

`#! /usr/bin/env cached-nix-shell`<br>
`#! nix-shell -i` _real-interpreter_ `-p` _packages_<br>

## DESCRIPTION

`cached-nix-shell` is a caching layer for `nix-shell` featuring instant startup time on subsequent runs.
The design goal is to make a fast drop-in replacement for `nix-shell`, including support of shebang scripts and non-interactive commands (i.e., `nix-shell --run ...`).

## OPTIONS

`cached-nix-shell` supports the majority of `nix-shell` options,
  see the corresponding man page for the list.

Additionally, the following new option is unique for `cached-nix-shell`:

* `--exec` _cmd_ \[_args_]... (not in shebang):
  Command and arguments to be executed.
  It is similar to `--run` except that the command is executed directly rather than as shell command.
  It should be slightly faster and more convenient to pass arguments.

## ENVIRONMENT VARIABLES

* `IN_CACHED_NIX_SHELL`:
  Is set to `1`.

## LIMITATIONS

Accessing network resources (e.g. via `builtins.fetchurl`) is not considered in cache invalidation logic.
Consequently, `tarball-ttl` option (see `nix-conf`(5)) is not respected.

## HOMEPAGE

<https://github.com/xzfc/cached-nix-shell>

Please report bugs and feature requests in the issue tracker.

## SEE ALSO

nix-shell(1)
