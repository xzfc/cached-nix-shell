# trace-nix

Using `LD_PRELOAD` trick to trace nix access to dirs and files.

## Usage

Run `nix-shell` (or `nix repl` or any other nix tool) with the following env var set:

* `TRACE_NIX_FD`: file descriptor number to write log to

Example:
``` bash
LD_PRELOAD=/path/to/intercept.so TRACE_NIX_FD=42 42>./log nix-shell -p stdenv --run :

# The NUL-separeted list of file names will be stored in `./log`
```
