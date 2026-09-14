"""Bringing the checkout to the state that is about to be built."""

from __future__ import annotations

import subprocess
from datetime import datetime
from pathlib import Path

from . import proc
from .config import Config


def clone(cfg: Config) -> None:
    """Create the checkout if it is not there yet.

    The clone goes into the configured repository path, submodules included,
    because a build without them fails late and confusingly rather than early.
    """
    parent = cfg.repo.parent
    proc.headline(f"Cloning {cfg.clone_url} into {cfg.repo}")
    if not cfg.dry_run:
        parent.mkdir(parents=True, exist_ok=True)
    proc.run(["git", "clone", "--recursive", "-b", cfg.branch,
              cfg.clone_url, cfg.repo.name], parent, dry_run=cfg.dry_run)


def update(cfg: Config, *, reset: bool = True) -> None:
    """Fetch and move the checkout onto the configured branch.

    This mirrors what the old ov-checkout.sh did, minus the private remote: it
    fetches, puts the work tree onto the branch, cleans the submodules and
    resets everything hard, so that a build never picks up a half-finished
    local edit. It deliberately does not run "git clean -xfd" in the top level,
    because that would also delete the bitbake output of previous builds.
    """
    repo = cfg.repo
    proc.headline(f"Updating {repo} to {cfg.remote}/{cfg.branch}")

    proc.run(["git", "fetch", cfg.remote], repo, dry_run=cfg.dry_run)
    proc.run(["git", "checkout", "-B", cfg.branch], repo, dry_run=cfg.dry_run)

    proc.run(["git", "submodule", "sync", "--recursive"], repo, dry_run=cfg.dry_run)
    proc.run(["git", "submodule", "foreach", "--recursive",
              "git", "clean", "-xfd"], repo, dry_run=cfg.dry_run)

    if reset:
        keep_what_would_be_lost(cfg)
        proc.run(["git", "reset", "--hard", f"{cfg.remote}/{cfg.branch}"],
                 repo, dry_run=cfg.dry_run)
        proc.run(["git", "submodule", "foreach", "--recursive",
                  "git", "reset", "--hard"], repo, dry_run=cfg.dry_run)

    proc.run(["git", "submodule", "update", "--init", "--recursive"],
             repo, dry_run=cfg.dry_run)


def keep_what_would_be_lost(cfg: Config) -> None:
    """Put a branch on commits that the coming reset would drop.

    A hard reset onto the remote branch throws away everything the work tree
    has on top of it. That is intended when the checkout only ever follows a
    remote, but one wrong OV_REMOTE - the default is origin, that is GitHub,
    while a build often follows a local clone - and the reset would discard
    work that exists nowhere else. Rather than refusing, the commits are kept
    under a dated branch, so the build can carry on and nothing is lost.
    """
    target = f"{cfg.remote}/{cfg.branch}"
    result = subprocess.run(
        ["git", "rev-list", "--count", f"{target}..HEAD"],
        cwd=str(cfg.repo), capture_output=True, text=True,
    )
    if result.returncode != 0:
        return
    try:
        ahead = int(result.stdout.strip())
    except ValueError:
        return
    if ahead == 0:
        return

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    name = f"backup/{cfg.branch}-before-reset-{stamp}"
    proc.say(f"    {ahead} commit(s) are not in {target}; keeping them as {name}")
    proc.run(["git", "branch", name, "HEAD"], cfg.repo, dry_run=cfg.dry_run,
             check=False)


def run(cfg: Config, *, reset: bool = True) -> None:
    if (cfg.repo / ".git").exists():
        update(cfg, reset=reset)
    else:
        clone(cfg)

    head = cfg.repo / "meta-openvario"
    if not cfg.dry_run and not head.is_dir():
        proc.die(f"{cfg.repo} does not look like an OpenVario checkout "
                 "(meta-openvario is missing)")
