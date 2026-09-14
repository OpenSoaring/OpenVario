"""Checking the host against the Yocto state that is about to be built.

A build fails late and unhelpfully when the distribution is newer than the
pinned Yocto release: bitbake dies in a Python traceback about ast.Str, or the
sanity checker stops on the uninative glibc limit after several minutes. Both
conditions can be read off before the first bitbake call, so they are.

The checks look at the tree, not at a table kept here: the glibc limit comes
from the oe-core the checkout actually carries, and the Python question is
answered by looking at the bitbake that will run. A tree that has been updated
therefore passes without anyone editing this file.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

from . import proc
from .config import Config

UNINATIVE_INC = Path("openembedded-core/meta/conf/distro/include/yocto-uninative.inc")
CODEPARSER = Path("bitbake/lib/bb/codeparser.py")


def _version_tuple(text: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r"\d+", text)[:3])


def host_glibc() -> str | None:
    """The glibc version of this host, without starting a process."""
    try:
        value = os.confstr("CS_GNU_LIBC_VERSION")
    except (ValueError, OSError):
        return None
    if not value:
        return None
    return value.split()[-1]


def max_glibc(cfg: Config) -> str | None:
    path = cfg.repo / UNINATIVE_INC
    if not path.is_file():
        return None
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r'\s*UNINATIVE_MAXGLIBCVERSION\s*=\s*"([^"]*)"', line)
        if m:
            return m.group(1)
    return None


def bitbake_handles_modern_python(cfg: Config) -> bool | None:
    """Whether the bitbake in the tree survives Python 3.12 and newer.

    ast.Str was removed in Python 3.12. Newer bitbake versions keep the name
    only inside a branch for Python older than 3.8 and use a helper called
    node_str_value elsewhere, so the presence of that helper is the reliable
    marker. None means the file was not found and nothing can be said.
    """
    path = cfg.repo / CODEPARSER
    if not path.is_file():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    if "ast.Str" not in text:
        return True
    return "node_str_value" in text


def run(cfg: Config, *, fatal: bool = True) -> None:
    """Report anything that will make the build fail, and stop if it will.

    On a dry run the findings are printed but nothing is stopped: the point of
    a dry run is to show what a real build would run into, and that includes
    this.
    """
    problems: list[str] = []

    limit = max_glibc(cfg)
    current = host_glibc()
    if limit and current:
        if _version_tuple(current) > _version_tuple(limit):
            problems.append(
                f"This host has glibc {current}, but the oe-core in this "
                f"checkout accepts at most {limit} "
                f"(UNINATIVE_MAXGLIBCVERSION). The sanity checker would stop "
                f"the build. Either build on an older distribution, or in a "
                f"container with OV_CONTAINER, or move the tree to a newer "
                f"Yocto release.")
        else:
            proc.say(f"    host glibc {current}, tree accepts up to {limit}")

    modern = bitbake_handles_modern_python(cfg)
    if modern is False and sys.version_info >= (3, 12):
        version = ".".join(str(n) for n in sys.version_info[:3])
        problems.append(
            f"This host runs Python {version}, and the bitbake in this "
            f"checkout still uses ast.Str, which Python removed in 3.12. "
            f"bitbake would die in a traceback while parsing. The same three "
            f"ways out apply: an older distribution, a container, or a newer "
            f"Yocto release.")

    if not problems:
        return

    proc.say("")
    for problem in problems:
        proc.say(f"    {problem}")
    proc.say("")
    if not fatal:
        proc.say("    (dry run, so the build is not stopped here)")
        return
    proc.die("the host does not match this checkout; pass --no-host-check to "
             "try anyway")
