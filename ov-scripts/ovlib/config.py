"""Settings for the OpenVario build scripts.

Everything that differs between one person's machine and the next lives in
environment variables, so that the scripts themselves stay free of local
paths, private remotes and publishing targets. A wrapper script outside the
repository sets those variables and then calls ov.py; the repository only
carries the defaults that are true for everyone.

The variables, all optional:

    OV_REPO         path of the OpenVario checkout (default: the repository
                    this script lives in)
    OV_REMOTE       git remote to fetch from (default: origin)
    OV_BRANCH       branch to build (default: master)
    OV_CLONE_URL    URL used when the checkout does not exist yet
    OV_MACHINES     machines to build, space or comma separated, or "all"
                    (default: ov-ch70)
    OV_IMAGE        image recipe to build (default: openvario-image)
    OV_RECOVERY     y or n, whether the two recovery images are built as well
                    (default: y)
    OV_DEPLOY_DIR   directory for the upgrade packages (default: <repo>/../Deploy)
    OV_PUBLISH_DIR  directory the finished files are copied to, for instance a
                    cloud folder (default: empty, nothing is published)
    OV_MIN_IMAGE_MB smallest plausible image in MiB; anything smaller is
                    treated as a failed build (default: 10)
"""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

MACHINE_CONF_DIR = Path("meta-openvario/conf/machine")
VERSIONS_INC = Path("meta-openvario/ov-versions.inc")
DEFAULT_CLONE_URL = "https://github.com/OpenSoaring/OpenVario"


def _env_flag(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    return raw.strip().lower() in ("y", "yes", "true", "1", "on")


def _find_repo(explicit: str | None) -> Path:
    """Locate the OpenVario checkout.

    Preference order: an explicit path, OV_REPO, the git work tree this file
    belongs to, and finally the parent of the ov-scripts directory. Asking git
    keeps the scripts usable from any working directory without cd .. games.
    """
    if explicit:
        return Path(explicit).expanduser().resolve()
    from_env = os.environ.get("OV_REPO")
    if from_env:
        return Path(from_env).expanduser().resolve()
    here = Path(__file__).resolve().parent.parent  # ov-scripts/
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=here, capture_output=True, text=True, check=True,
        )
        return Path(out.stdout.strip()).resolve()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return here.parent


def _split_list(raw: str) -> list[str]:
    return [item for item in re.split(r"[,\s]+", raw.strip()) if item]


@dataclass
class Config:
    repo: Path
    remote: str
    branch: str
    clone_url: str
    machines: list[str]
    image: str
    build_recovery: bool
    deploy_dir: Path
    publish_dir: Path | None
    min_image_bytes: int
    dry_run: bool = False
    versions: dict[str, str] = field(default_factory=dict)

    # -- derived information -------------------------------------------------

    @property
    def ov_version(self) -> str:
        return self.versions.get("OV_VERSION", "")

    @property
    def opensoar_version(self) -> str:
        return self.versions.get("OPENSOAR_VERSION", "")

    def deploy_image_dir(self, machine: str) -> Path:
        return self.repo / "tmp" / "deploy" / "images" / machine

    def short_machine(self, machine: str) -> str:
        """Read SHORT_OV_MACHINE from the machine configuration.

        The short name appears in the image file name and is not derivable from
        the machine name by upper-casing: ov-am70s becomes AM70s, ov-hdmi
        becomes HDMI. Reading the value keeps the scripts in step with the
        layer even when a machine is added.
        """
        conf = self.repo / MACHINE_CONF_DIR / f"{machine}.conf"
        if conf.is_file():
            for line in conf.read_text(encoding="utf-8", errors="replace").splitlines():
                m = re.match(r'\s*SHORT_OV_MACHINE\s*=\s*"([^"]*)"', line)
                if m:
                    return m.group(1)
        return machine.removeprefix("ov-").upper()

    def has_short_name(self, machine: str) -> bool:
        """Whether the machine configuration defines SHORT_OV_MACHINE.

        A machine without it cannot produce a properly named SD card image,
        because SDIMG_LINK is built from that variable. ov-cubieboard is such a
        case: an experimental definition for a bare Cubieboard 1, not an
        OpenVario device. Machines like that stay out of "all".
        """
        conf = self.repo / MACHINE_CONF_DIR / f"{machine}.conf"
        if not conf.is_file():
            return False
        return "SHORT_OV_MACHINE" in conf.read_text(encoding="utf-8", errors="replace")

    def known_machines(self, only_named: bool = False) -> list[str]:
        conf_dir = self.repo / MACHINE_CONF_DIR
        if not conf_dir.is_dir():
            return []
        machines = sorted(p.stem for p in conf_dir.glob("ov-*.conf"))
        if only_named:
            machines = [m for m in machines if self.has_short_name(m)]
        return machines


def read_versions(repo: Path) -> dict[str, str]:
    """Parse meta-openvario/ov-versions.inc.

    The file uses shell assignment syntax so that bitbake and plain shell
    scripts can read the same source; here we need the same values without
    starting a shell.
    """
    versions: dict[str, str] = {}
    # VERSION.inc in the root is where the image version lived before it moved
    # into the layer; reading it as a fallback keeps the scripts working on an
    # older checkout.
    for candidate in (repo / VERSIONS_INC, repo / "VERSION.inc"):
        if not candidate.is_file():
            continue
        for line in candidate.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            m = re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"?([^"#]*)"?', line)
            if m:
                versions.setdefault(m.group(1), m.group(2).strip())
    return versions


def load(args) -> Config:
    repo = _find_repo(getattr(args, "repo", None))

    machines_raw = getattr(args, "machines", None) or os.environ.get("OV_MACHINES", "ov-ch70")
    versions = read_versions(repo)

    cfg = Config(
        repo=repo,
        remote=os.environ.get("OV_REMOTE", "origin"),
        branch=os.environ.get("OV_BRANCH", "master"),
        clone_url=os.environ.get("OV_CLONE_URL", DEFAULT_CLONE_URL),
        machines=[],
        image=os.environ.get("OV_IMAGE", "openvario-image"),
        build_recovery=_env_flag("OV_RECOVERY", True),
        deploy_dir=Path(os.environ.get("OV_DEPLOY_DIR", str(repo.parent / "Deploy"))).expanduser(),
        publish_dir=(Path(os.environ["OV_PUBLISH_DIR"]).expanduser()
                     if os.environ.get("OV_PUBLISH_DIR") else None),
        min_image_bytes=int(os.environ.get("OV_MIN_IMAGE_MB", "10")) * 1024 * 1024,
        dry_run=bool(getattr(args, "dry_run", False)),
        versions=versions,
    )

    if machines_raw.strip().lower() == "all":
        cfg.machines = cfg.known_machines(only_named=True)
    else:
        cfg.machines = _split_list(machines_raw)

    if getattr(args, "branch", None):
        cfg.branch = args.branch
    if getattr(args, "image", None):
        cfg.image = args.image
    if getattr(args, "no_recovery", False):
        cfg.build_recovery = False

    return cfg


def describe(cfg: Config) -> str:
    lines = [
        f"repository   : {cfg.repo}",
        f"remote/branch: {cfg.remote}/{cfg.branch}",
        f"machines     : {' '.join(cfg.machines) if cfg.machines else '(none)'}",
        f"image        : {cfg.image}" + ("  (plus recovery images)" if cfg.build_recovery else ""),
        f"deploy dir   : {cfg.deploy_dir}",
        f"publish dir  : {cfg.publish_dir if cfg.publish_dir else '(not set, nothing is published)'}",
        f"OV version   : {cfg.ov_version or '(unknown)'}",
        f"OpenSoar     : {cfg.opensoar_version or '(unknown)'}",
    ]
    if cfg.dry_run:
        lines.append("mode         : dry run, no command is executed")
    return "\n".join(lines)
