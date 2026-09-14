"""Running commands, with a dry run mode.

Every external command goes through here, so that --dry-run can print what
would happen without touching anything, and so that failures are reported the
same way everywhere instead of being swallowed.
"""

from __future__ import annotations

import shlex
import subprocess
import sys
from pathlib import Path


class CommandFailed(RuntimeError):
    def __init__(self, command: str, code: int):
        super().__init__(f"command failed with exit code {code}: {command}")
        self.command = command
        self.code = code


def say(message: str) -> None:
    print(message, flush=True)


def headline(message: str) -> None:
    print("", flush=True)
    print("=" * len(message), flush=True)
    print(message, flush=True)
    print("=" * len(message), flush=True)


def run(argv: list[str], cwd: Path, *, dry_run: bool, env: dict | None = None,
        check: bool = True) -> int:
    printable = " ".join(shlex.quote(a) for a in argv)
    say(f"    $ {printable}    [in {cwd}]")
    if dry_run:
        return 0
    result = subprocess.run(argv, cwd=str(cwd), env=env)
    if check and result.returncode != 0:
        raise CommandFailed(printable, result.returncode)
    return result.returncode


def run_in_bitbake_env(command: str, cwd: Path, *, dry_run: bool,
                       env: dict | None = None) -> int:
    """Run a command with the bitbake environment in place.

    oe-init-build-env has to be sourced, and it only works in a shell, so the
    command is handed to bash rather than executed directly. The build
    directory is the repository root itself, which is what the OpenVario tree
    expects ("oe-init-build-env ." in its own documentation).
    """
    init = "openembedded-core/oe-init-build-env"
    if not (cwd / init).is_file() and not dry_run:
        raise FileNotFoundError(
            f"{init} not found under {cwd}. Are the submodules checked out?")
    full = f"source {init} . >/dev/null && {command}"
    say(f"    $ bash -c {shlex.quote(full)}    [in {cwd}]")
    if dry_run:
        return 0
    result = subprocess.run(["bash", "-c", full], cwd=str(cwd), env=env)
    if result.returncode != 0:
        raise CommandFailed(command, result.returncode)
    return result.returncode


def die(message: str) -> None:
    print(f"error: {message}", file=sys.stderr, flush=True)
    raise SystemExit(1)
