# cached-nix-shell - instant startup time for nix-shell(1)

## SYNOPSIS

`cached-nix-shell` \[_options_]...<br>
`cached-nix-shell` _shebang-script_ \[_args_]...<br>
`cached-nix-shell --wrap` _cmd_ \[_args_]...<br>

## DESCRIPTION

`cached-nix-shell` is a caching layer for `nix-shell` featuring instant startup time on subsequent runs.
The design goal is to make a fast drop-in replacement for `nix-shell`, including support of shebang scripts and non-interactive commands (i.e., `nix-shell --run ...`).

## OPTIONS

`cached-nix-shell` supports the majority of `nix-shell` options,
  see the corresponding man page for the list.

Additionally, the following new options are unique for `cached-nix-shell`:

* `--exec` _cmd_ \[_args_]... (not in shebang):
  Command and arguments to be executed.
  It is similar to `--run` except that the command is executed directly rather than as shell command.
  It should be slightly faster and more convenient to pass arguments.

* `--wrap` _cmd_ \[_args_]... (not in shebang, should be the first arg):
  Run the command substituting every invocation of `nix-shell` with `cached-nix-shell`.
  This is done by adding our symlink named `nix-shell` to the `$PATH`.

## ENVIRONMENT VARIABLES

* `IN_CACHED_NIX_SHELL`:
  Is set to `1`.

## FILES

The cache is stored in `$XDG_CACHE_HOME/cached-nix-shell`,
  defaults to `~/.cache/cached-nix-shell`.

## LIMITATIONS

* Ambient environment variables:
It is necessary to pass `--keep` _var_ even without `--pure`
  if the variable _var_ is used inside a nix expression or a hook.
Note that updating the value of _var_ would invalidate the cache.

* Relative paths:
When `--expr` or `--packages` option is given,
  the cache is evaluated inside a separate empty directory,
  preventing access to relative paths from within nix expressions.
Contrariwise, when a path to a shebang script or nix file is given,
  the cache is evaluated in the directory containing that script or file.
This allows multiple `cached-nix-shell` invocations
  from different directories to reuse the same cache entry.

* Network access:
Accessing network resources (e.g. via `builtins.fetchurl`) is not considered in cache invalidation logic.
Consequently, `tarball-ttl` option (see `nix-conf`(5)) is not respected.

* Bash variables and functions:
Only exported environment variables are preserved,
  but not global shell variables and functions set by `setup.sh`.

* Shell hooks:
Shell hooks are executed only once, during a cache evaluation.

## HOMEPAGE

<https://github.com/xzfc/cached-nix-shell>

Please report bugs and feature requests in the issue tracker.

## SEE ALSO

nix-shell(1)
