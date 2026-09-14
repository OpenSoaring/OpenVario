"""Turning a finished image into the upgrade package.

This is the part that used to live in the second half of ov-build-machine.sh:
collect the image bitbake produced, cut the boot sector out of it, add the
recovery image and the two upgrade scripts, and pack the result into the zip
that goes onto a USB stick. Where the files end up is configuration, so the
same code serves anyone building the image.
"""

from __future__ import annotations

import gzip
import shutil
import zipfile
from pathlib import Path

from . import proc
from .config import Config

BOOTSECTOR_KIB = 2024
FW_UPGRADE = Path("meta-openvario/recipes-apps/ovmenu-ng-skripts/files/fw-upgrade.sh")
UPDATE_CONFIG = Path("meta-openvario/recipes-apps/ovmenu-ng-skripts/files/update-system-config.sh")


def find_image(cfg: Config, machine: str) -> Path:
    """Locate the compressed SD card image for one machine.

    The image class writes the file name it used into "image_link" next to the
    image, so that is the reliable source. Only if that file is missing do we
    fall back to composing the name from the version and the short machine
    name, the way the class does.
    """
    image_dir = cfg.deploy_image_dir(machine)
    link = image_dir / "image_link"
    if link.is_file():
        name = link.read_text(encoding="utf-8", errors="replace").strip()
        if name:
            candidate = image_dir / f"{name}.gz"
            if candidate.is_file():
                return candidate
    short = cfg.short_machine(machine)
    candidate = image_dir / f"OV-{cfg.ov_version}-CB2-{short}.img.gz"
    return candidate


def write_bootsector(cfg: Config, image_gz: Path, target: Path) -> None:
    """Extract the first blocks of the image and store them compressed.

    The recovery menu writes this back to a card whose boot sector is broken,
    so it has to be exactly the leading part of the very image that is being
    shipped, not of some earlier build.
    """
    proc.say(f"    boot sector -> {target}")
    if cfg.dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    with gzip.open(image_gz, "rb") as src, gzip.open(target, "wb") as dst:
        remaining = BOOTSECTOR_KIB * 1024
        while remaining > 0:
            chunk = src.read(min(1024 * 1024, remaining))
            if not chunk:
                break
            dst.write(chunk)
            remaining -= len(chunk)
        if remaining > 0:
            raise RuntimeError(
                f"{image_gz} holds less than {BOOTSECTOR_KIB} KiB; "
                "it cannot be a complete SD card image")


def copy(cfg: Config, source: Path, target: Path) -> None:
    proc.say(f"    {source.name} -> {target}")
    if cfg.dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def make_zip(cfg: Config, folder: Path, archive: Path) -> None:
    proc.say(f"    packing {folder} -> {archive}")
    if cfg.dry_run:
        return
    archive.parent.mkdir(parents=True, exist_ok=True)
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(folder.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(folder).as_posix())


def deploy_machine(cfg: Config, machine: str) -> Path | None:
    short = cfg.short_machine(machine)
    proc.headline(f"Packaging {machine} ({short}), OV {cfg.ov_version}")

    image_gz = find_image(cfg, machine)
    if not cfg.dry_run:
        if not image_gz.is_file():
            proc.die(f"image not found: {image_gz}")
        size = image_gz.stat().st_size
        if size < cfg.min_image_bytes:
            proc.die(f"{image_gz} is only {size} bytes; the build did not "
                     "produce a usable image")
        proc.say(f"    image: {image_gz} ({size // (1024 * 1024)} MiB)")
    else:
        proc.say(f"    image: {image_gz}")

    machine_dir = cfg.deploy_dir / short
    images_dir = machine_dir / "openvario" / "images"

    # Only ever remove images of earlier runs inside the deploy directory, so
    # that the zip does not end up carrying two versions at once.
    if not cfg.dry_run and images_dir.is_dir():
        for stale in images_dir.glob("OV-*.img.gz"):
            proc.say(f"    removing earlier image {stale.name}")
            stale.unlink()

    copy(cfg, image_gz, images_dir / image_gz.name)
    write_bootsector(cfg, image_gz, images_dir / short / "bootsector.bin.gz")

    recovery = cfg.deploy_image_dir(machine) / "ov-recovery.itb"
    if cfg.dry_run or recovery.is_file():
        copy(cfg, recovery, images_dir / short / "ov-recovery.itb")
    else:
        proc.say(f"    note: {recovery} is missing, the package will have no "
                 "recovery image")

    copy(cfg, cfg.repo / FW_UPGRADE, machine_dir / "fw-upgrade.sh")
    copy(cfg, cfg.repo / UPDATE_CONFIG, machine_dir / "openvario" / "update-system-config.sh")

    version_dir = cfg.deploy_dir / cfg.ov_version
    archive = version_dir / f"Upgrade-OV-{short}-v{cfg.ov_version}.zip"
    make_zip(cfg, machine_dir, archive)
    copy(cfg, image_gz, version_dir / image_gz.name)

    if cfg.publish_dir:
        # Without a known OpenSoar version there is no sensible directory to
        # sort by, and a bare "v" would be worse than none at all.
        target = cfg.publish_dir
        if cfg.opensoar_version:
            target = target / f"v{cfg.opensoar_version}"
        target = target / f"OV-{cfg.ov_version}"
        proc.say(f"    publishing to {target}")
        copy(cfg, image_gz, target / image_gz.name)
        copy(cfg, archive, target / archive.name)

    return archive


def run(cfg: Config) -> None:
    if not cfg.ov_version:
        proc.die("OV_VERSION is unknown; meta-openvario/ov-versions.inc could "
                 "not be read")
    for machine in cfg.machines:
        deploy_machine(cfg, machine)
