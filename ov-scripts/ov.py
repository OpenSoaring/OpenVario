#!/usr/bin/env python3
"""Build entry point for the OpenVario image.

    python3 ov-scripts/ov.py config
    python3 ov-scripts/ov.py checkout
    python3 ov-scripts/ov.py build --machines "ov-ch57 ov-ch70"
    python3 ov-scripts/ov.py deploy
    python3 ov-scripts/ov.py all --machines all

The script is called with the interpreter, so it needs no execute bit; a
checkout made under Windows works as it is. Everything that is specific to one
person - remotes, branches, where finished images go - comes from environment
variables, described in ovlib/config.py, and is meant to be set by a small
wrapper outside the repository.
"""

from __future__ import annotations

import argparse
import signal
import sys
from pathlib import Path

# Writing into a closed pipe - "ov.py machines | head" - should end the script
# quietly instead of printing a traceback. Windows has no SIGPIPE.
try:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
except (AttributeError, ValueError):
    pass

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ovlib import build, checkout, config, deploy, proc  # noqa: E402


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build and package the OpenVario image.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--repo", help="path of the OpenVario checkout")
    parser.add_argument("--machines", help='machines, space separated, or "all"')
    parser.add_argument("--branch", help="branch to build")
    parser.add_argument("--image", help="image recipe to build")
    parser.add_argument("--no-recovery", action="store_true",
                        help="skip the two recovery images")
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="only show what would be done")

    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("config", help="show the settings in effect and stop")
    co = sub.add_parser("checkout", help="fetch and reset the checkout")
    co.add_argument("--no-reset", action="store_true",
                    help="do not reset the work tree, keep local changes")
    sub.add_parser("build", help="run bitbake for the selected machines")
    sub.add_parser("deploy", help="package the images that were built")
    allc = sub.add_parser("all", help="checkout, build and deploy in one go")
    allc.add_argument("--no-reset", action="store_true",
                      help="do not reset the work tree, keep local changes")
    sub.add_parser("machines", help="list the machines the layer defines")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = make_parser().parse_args(argv)
    cfg = config.load(args)

    try:
        if args.command == "config":
            print(config.describe(cfg))
            return 0

        if args.command == "machines":
            for machine in cfg.known_machines():
                if cfg.has_short_name(machine):
                    print(f"{machine}\t{cfg.short_machine(machine)}")
                else:
                    print(f"{machine}\t-  (no SHORT_OV_MACHINE, not part of \"all\")")
            return 0

        print(config.describe(cfg))

        if args.command in ("checkout", "all"):
            checkout.run(cfg, reset=not getattr(args, "no_reset", False))
            # The versions may have changed with the checkout.
            cfg.versions = config.read_versions(cfg.repo)

        if args.command in ("build", "all"):
            build.run(cfg)

        if args.command in ("deploy", "all"):
            deploy.run(cfg)

    except proc.CommandFailed as exc:
        proc.die(str(exc))
    except FileNotFoundError as exc:
        proc.die(str(exc))
    except KeyboardInterrupt:
        print("", flush=True)
        proc.die("interrupted")

    proc.headline("Finished")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
