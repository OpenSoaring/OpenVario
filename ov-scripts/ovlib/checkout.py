"""Bringing the checkout to the state that is about to be built."""

from __future__ import annotations

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
        proc.run(["git", "reset", "--hard", f"{cfg.remote}/{cfg.branch}"],
                 repo, dry_run=cfg.dry_run)
        proc.run(["git", "submodule", "foreach", "--recursive",
                  "git", "reset", "--hard"], repo, dry_run=cfg.dry_run)

    proc.run(["git", "submodule", "update", "--init", "--recursive"],
             repo, dry_run=cfg.dry_run)


def run(cfg: Config, *, reset: bool = True) -> None:
    if (cfg.repo / ".git").exists():
        update(cfg, reset=reset)
    else:
        clone(cfg)

    head = cfg.repo / "meta-openvario"
    if not cfg.dry_run and not head.is_dir():
        proc.die(f"{cfg.repo} does not look like an OpenVario checkout "
                 "(meta-openvario is missing)")
