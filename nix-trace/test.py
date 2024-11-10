#!/usr/bin/env python3

import os
import shutil
import subprocess
import sys
import threading
import types
import typing


def main() -> None:
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    shutil.rmtree("test-tmp", ignore_errors=True)
    os.makedirs("test-tmp/repo/data")
    os.makedirs("test-tmp/tmpdir")
    with open("test-tmp/test.nix", "w") as f:
        f.write('"foo"')
    open("test-tmp/empty", "w").close()
    os.symlink("empty", "test-tmp/link")
    with open("test-tmp/repo/data/default.nix", "w") as f:
        f.write("{}")
    subprocess.run("tar -C test-tmp/repo -cf test-tmp/repo.tar .", shell=True)
    for i in range(64):
        os.makedirs(b"test-tmp/many-dirs/x" + b"x" * i)

    versions = [18, 19, 20, 21, 22, 23, 24, 90, 91]
    with TablePrinter([f"2.{i}" for i in versions]) as tp:
        threads = []
        for v in versions:
            threads.append(threading.Thread(target=run_tests, args=(v, tp)))

        for t in threads:
            t.start()

        for t in threads:
            t.join()


def run_tests(version: int, tp: "TablePrinter") -> None:
    try:
        impl = "lix" if version >= 90 else "nix"
        nix_shell_bin = (
            subprocess.check_output(
                [
                    "nix-build",
                    "--no-out-link",
                    "<nixpkgs>",
                    "-A",
                    f"{impl}Versions.{impl}_2_{version}",
                ],
            ).rstrip(b"\n")
            + b"/bin/nix-shell"
        )
    except subprocess.CalledProcessError:
        return

    tc = testcase(tp, f"2.{version}", nix_shell_bin)

    # Tests
    unstable_path = b"/nix/var/nix/profiles/per-user/root/channels/unstable"
    if os.path.islink(unstable_path):
        r = tc.run("-p", "with import <unstable> {}; bash")
        r.check(
            "import-channel", b"s" + unstable_path, b"l" + os.readlink(unstable_path)
        )

    r = tc.run("-p", "with import <nonexistentChannel> {}; bash")
    r.check(
        "import-channel-ne",
        b"s/nix/var/nix/profiles/per-user/root/channels/nonexistentChannel",
        b"-",
    )

    r = tc.run("-p", "import ./test-tmp/test.nix")
    r.check("import-relative-nix", b"s" + os.getcwdb() + b"/test-tmp/test.nix", b"+")

    r = tc.run("-p", "import ./test-tmp")
    r.check("import-relative-nix-dir", b"s" + os.getcwdb() + b"/test-tmp", b"d")

    r = tc.run("-p", "import ./nonexistent.nix")
    r.check("import-relative-nix-ne", b"s" + os.getcwdb() + b"/nonexistent.nix", b"-")

    r = tc.run("-p", "builtins.readFile ./test-tmp/test.nix")
    r.check(
        "builtins.readFile",
        b"f" + os.getcwdb() + b"/test-tmp/test.nix",
        b3sum(file=b"./test-tmp/test.nix"),
    )

    r = tc.run("-p", 'builtins.readFile "/nonexistent/readFile"')
    r.check("builtins.readFile-ne", b"f/nonexistent/readFile", b"-")

    r = tc.run("-p", "builtins.readFile ./test-tmp")
    r.check("builtins.readFile-dir", b"f" + os.getcwdb() + b"/test-tmp", b"e")

    r = tc.run("-p", "builtins.readFile ./test-tmp/empty")
    r.check(
        "builtins.readFile-empty",
        b"f" + os.getcwdb() + b"/test-tmp/empty",
        b3sum(file=b"./test-tmp/empty"),
    )

    r = tc.run("-p", "builtins.readDir ./test-tmp")
    r.check(
        "builtins.readDir",
        b"d" + os.getcwdb() + b"/test-tmp",
        dir_b3sum(b"./test-tmp"),
    )

    r = tc.run("-p", 'builtins.readDir "/nonexistent/readDir"')
    r.check("builtins.readDir-ne", b"d/nonexistent/readDir", b"-")

    r = tc.run("-p", "builtins.readDir ./test-tmp/many-dirs")
    r.check(
        "builtins.readDir-many-dirs",
        b"d" + os.getcwdb() + b"/test-tmp/many-dirs",
        dir_b3sum(b"test-tmp/many-dirs"),
    )

    r = tc.run()
    r.check("implicit:shell.nix", b"s" + os.getcwdb() + b"/shell.nix", b"-")
    r.check("implicit:default.nix", b"s" + os.getcwdb() + b"/default.nix", b"-")

    if version <= 20 or version >= 90:
        r = tc.run("-p", f"fetchTarball file://{os.getcwd()}/test-tmp/repo.tar?1")
        tmp_path = tc.base_dir + b"/tmpdir/nix-" + str(r.pid).encode() + b"-1"
        r.check("fetchTarball:create", b"t" + tmp_path, b"+")
        r.check("fetchTarball:delete", b"t" + tmp_path, b"-")

        r = tc.run(
            "-I", f"q=file://{os.getcwd()}/test-tmp/repo.tar?2", "-p", "import <q>"
        )
        tmp_path = tc.base_dir + b"/tmpdir/nix-" + str(r.pid).encode() + b"-1"
        r.check("tarball-I:create", b"t" + tmp_path, b"+")
        r.check("tarball-I:delete", b"t" + tmp_path, b"-")


class TablePrinter:
    ROW_HEADER = 30

    def __init__(self, cols: list[str]) -> None:
        self._mutex = threading.Lock()

        self.checks: list[str] = []
        self.cols = cols
        self.cols_positions = [self.ROW_HEADER + 1]
        for col in cols:
            self.cols_positions.append(self.cols_positions[-1] + len(col) + 1)
        print(end="\x1b7\n")
        print(" " * self.ROW_HEADER + " ".join(cols))

    def __enter__(self) -> "TablePrinter":
        self._stop = False

        sys.stdout.flush()
        sys.stderr.flush()

        self._orig_fd = os.dup(sys.stdout.fileno()), os.dup(sys.stderr.fileno())
        self._new_fd, new_fd = os.pipe()
        os.dup2(new_fd, sys.stdout.fileno())
        os.dup2(new_fd, sys.stderr.fileno())
        os.close(new_fd)
        self._thread = threading.Thread(target=self._stderr_thread)
        self._thread.start()

        return self

    def __exit__(
        self,
        _exc_type: type[BaseException] | None,
        _exc_value: BaseException | None,
        _traceback: types.TracebackType | None,
    ) -> None:
        self._stop = True
        os.write(sys.stderr.fileno(), b"\0")
        self._thread.join()

    def _stderr_thread(self) -> None:
        while True:
            line = os.read(self._new_fd, 4096)
            if not line:
                break

            with self._mutex:
                text = [b"\x1b8"]
                for x in line.splitlines(True):
                    text.append(x)
                    if x.endswith(b"\n"):
                        text.append(b"\x1b[L")
                text.append(b"\x1b7")
                text.append(b"\x1b[%dB" % (len(self.checks) + 2))
                text = b"".join(text)

                pos = 0
                while pos < len(text):
                    pos += os.write(self._orig_fd[0], text)

                if self._stop:
                    os.dup2(self._orig_fd[0], sys.stdout.fileno())
                    os.dup2(self._orig_fd[1], sys.stderr.fileno())
                    os.close(self._new_fd)
                    break

    def add_result(self, col: str, check: str, ok: bool) -> None:
        col_idx = self.cols.index(col)
        cell = b"\033[32mOK\033[m" if ok else b"\033[31mFAIL\033[m"

        res = []
        if check in self.checks:
            idx = self.checks.index(check)
            res.append(b"\x1b[%dA" % (len(self.checks) - idx))
            res.append(b"\x1b[%dG" % self.cols_positions[col_idx])
            res.append(cell)
            res.append(b"\x1b[%dB" % (len(self.checks) - idx))
        else:
            self.checks.append(check)
            res.append(b"\r")
            res.append(check.encode())
            res.append(b"\x1b[%dG" % self.cols_positions[col_idx])
            res.append(cell)
            res.append(b"\n")
        res = b"".join(res)

        with self._mutex:
            os.write(self._orig_fd[0], res)


class testcase:
    def __init__(self, tp: TablePrinter, name: str, nix: bytes) -> None:
        self.tp = tp
        self.name = name
        self.nix = nix
        self.counter = 0

        self.base_dir = os.getcwdb() + b"/test-tmp/v/" + name.encode()
        os.makedirs(self.base_dir + b"/tmpdir")
        os.makedirs(self.base_dir + b"/xdg-cache")
        os.makedirs(self.base_dir + b"/log")

    def run(self, *args: str) -> "RunResults":
        log_path = self.base_dir + b"/log/" + str(self.counter).encode()
        self.counter += 1
        process = subprocess.Popen(
            [self.nix, "--run", ":", *args],
            env={
                **os.environb.copy(),
                b"DYLD_INSERT_LIBRARIES": os.getcwdb() + b"/build/trace-nix.so",
                b"LD_PRELOAD": os.getcwdb() + b"/build/trace-nix.so",
                b"TRACE_NIX": log_path,
                b"XDG_CACHE_HOME": self.base_dir + b"/xdg-cache",
                b"TMPDIR": self.base_dir + b"/tmpdir",
            },
            stderr=subprocess.DEVNULL,
        )
        process.wait()

        with open(log_path, "rb") as f:
            content = f.read().split(b"\0")
        it = iter(content)
        log = list(zip(it, it))

        return RunResults(tc=self, pid=process.pid, log=log)


class RunResults(typing.NamedTuple):
    tc: "testcase"
    pid: int
    log: list[tuple[bytes, bytes]]

    def check(self, name: str, key: bytes, val: bytes) -> None:
        values = [item[1] for item in self.log if item[0] == key]
        self.tc.tp.add_result(self.tc.name, name, val in values)


def b3sum(*, file: bytes | str | None = None, input: bytes | None = None) -> bytes:
    return subprocess.check_output(["b3sum", file or "-"], input=input)[:32]


def dir_b3sum(directory: bytes) -> bytes:
    def entry_type(e: os.DirEntry[bytes]) -> bytes:
        # fmt: off
        return (b"l" if e.is_symlink() else
                b"d" if e.is_dir(follow_symlinks=False) else
                b"f" if e.is_file(follow_symlinks=False) else
                b"u")
        # fmt: on

    return b3sum(
        input=b"".join(
            sorted(e.name + b"=" + entry_type(e) + b"\0" for e in os.scandir(directory))
        )
    )


if __name__ == "__main__":
    main()
