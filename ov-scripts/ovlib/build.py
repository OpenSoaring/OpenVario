"""Running bitbake for one or more machines."""

from __future__ import annotations

from . import hostcheck, proc
from .config import Config

RECOVERY_TARGETS = ["openvario-recovery-initramfs", "openvario-recovery-image"]


def targets_for(cfg: Config) -> list[str]:
    """The recipes to build, in the order they depend on each other.

    The recovery initramfs has to exist before the recovery image can pack it,
    and the OpenVario image comes last because it is the longest job; a failure
    in one of the small ones should surface before an hour of compiling.
    """
    targets = []
    if cfg.build_recovery:
        targets.extend(RECOVERY_TARGETS)
    targets.append(cfg.image)
    return targets


def build_machine(cfg: Config, machine: str) -> None:
    proc.headline(f"Building for MACHINE={machine}")
    for target in targets_for(cfg):
        proc.say(f"--- {target} ({machine}) ---")
        proc.run_in_bitbake_env(f"bitbake {target}", cfg.repo,
                                dry_run=cfg.dry_run,
                                env_vars={"MACHINE": machine}, cfg=cfg)


def run(cfg: Config, *, host_check: bool = True) -> None:
    if not cfg.machines:
        proc.die("no machines selected; set OV_MACHINES or pass --machines")
    # A container brings its own userspace, so the host does not have to match.
    if host_check and not cfg.container:
        hostcheck.run(cfg, fatal=not cfg.dry_run)
    for machine in cfg.machines:
        conf = cfg.repo / "meta-openvario" / "conf" / "machine" / f"{machine}.conf"
        if not cfg.dry_run and not conf.is_file():
            proc.die(f"unknown machine {machine}: {conf} does not exist")
    for machine in cfg.machines:
        build_machine(cfg, machine)
