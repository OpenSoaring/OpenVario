"""Running commands, with a dry run mode.

Every external command goes through here, so that --dry-run can print what
would happen without touching anything, and so that failures are reported the
same way everywhere instead of being swallowed.
"""

from __future__ import annotations

import os
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


def container_command(cfg, inner: str, env_vars: dict) -> list[str]:
    """Build the run command that carries bitbake into a container.

    The checkout is mounted under the very path it has on the host. Yocto
    stores absolute paths in tmp/ and in the sstate cache, so a build inside
    the container and one outside can only share those when the path is
    identical; mounting it elsewhere would quietly invalidate the cache and
    make the two ways of building mutually exclusive.

    The build runs as the calling user, because bitbake refuses to run as
    root and because everything it writes has to stay editable outside the
    container afterwards.
    """
    argv = [cfg.container_runtime, "run", "--rm",
            "-v", f"{cfg.repo}:{cfg.repo}",
            "-w", str(cfg.repo),
            "-u", f"{os.getuid()}:{os.getgid()}"]
    for name, value in env_vars.items():
        argv += ["-e", f"{name}={value}"]
    argv += cfg.container_args
    argv += [cfg.container, "bash", "-c", inner]
    return argv


def run_in_bitbake_env(command: str, cwd: Path, *, dry_run: bool,
                       env_vars: dict | None = None, cfg=None) -> int:
    """Run a command with the bitbake environment in place.

    oe-init-build-env has to be sourced, and it only works in a shell, so the
    command is handed to bash rather than executed directly. The build
    directory is the repository root itself, which is what the OpenVario tree
    expects ("oe-init-build-env ." in its own documentation).

    With a container configured, the same shell line runs inside it; without
    one it runs on the host. Both ways build into the same tmp/ and share the
    sstate cache.
    """
    env_vars = env_vars or {}
    init = "openembedded-core/oe-init-build-env"
    if not (cwd / init).is_file() and not dry_run:
        raise FileNotFoundError(
            f"{init} not found under {cwd}. Are the submodules checked out?")
    inner = f"source {init} . >/dev/null && {command}"

    if cfg is not None and cfg.container:
        argv = container_command(cfg, inner, env_vars)
        return run(argv, cwd, dry_run=dry_run)

    say(f"    $ bash -c {shlex.quote(inner)}    [in {cwd}]")
    if dry_run:
        return 0
    env = os.environ.copy()
    env.update({k: str(v) for k, v in env_vars.items()})
    result = subprocess.run(["bash", "-c", inner], cwd=str(cwd), env=env)
    if result.returncode != 0:
        raise CommandFailed(command, result.returncode)
    return result.returncode


def die(message: str) -> None:
    print(f"error: {message}", file=sys.stderr, flush=True)
    raise SystemExit(1)
