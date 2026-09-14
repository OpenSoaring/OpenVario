# Build scripts

`ov.py` drives a build from the checkout to the finished upgrade package.

```
python3 ov-scripts/ov.py config                         # show settings, do nothing
python3 ov-scripts/ov.py machines                       # machines the layer defines
python3 ov-scripts/ov.py checkout                       # fetch and reset the tree
python3 ov-scripts/ov.py build --machines "ov-ch57 ov-ch70"
python3 ov-scripts/ov.py deploy
python3 ov-scripts/ov.py all --machines all
python3 ov-scripts/ov.py -n all                         # dry run, prints commands only
```

The scripts are started with the interpreter rather than through a shebang, so
they need no execute bit; a checkout made under Windows and used from WSL works
as it is. They use nothing but the Python standard library.

## What happens in which step

`checkout` fetches the configured remote, puts the work tree on the configured
branch, cleans and updates the submodules and resets hard. It does not run
`git clean -xfd` at the top level, because that would delete the bitbake output
of earlier builds along with everything else.

If the work tree carries commits that the remote branch does not have, they are
put on a branch `backup/<branch>-before-reset-<timestamp>` before the reset
throws them away. This matters because the default remote is `origin`, that is
GitHub, while a build often follows a local clone: a forgotten `OV_REMOTE` would
otherwise discard work that exists nowhere else.

`build` runs bitbake for every selected machine, in the order recovery
initramfs, recovery image, OpenVario image. Since bitbake needs the environment
that `oe-init-build-env` sets up, each call goes through `bash -c 'source ... &&
bitbake ...'` with `MACHINE` in the environment.

## The host check

Before the first bitbake call, `build` compares this host with the Yocto state
in the checkout and stops with one sentence rather than letting the build fail
minutes later in a traceback. Two things are compared: the glibc of the host
against `UNINATIVE_MAXGLIBCVERSION` of the oe-core in the tree, and, for Python
3.12 and newer, whether the bitbake in the tree still uses `ast.Str`, which
Python removed in that version.

Both values are read from the tree, not from a table in the scripts, so a tree
that has been updated passes on its own. The check is skipped when building in
a container, because the container brings its own userspace; on a dry run it
reports but does not stop; and `--no-host-check` overrides it.

## With or without a container

By default bitbake runs directly on the host, which needs a distribution the
pinned Yocto release supports. Setting `OV_CONTAINER` to an image runs the very
same shell line inside that image instead:

```
OV_CONTAINER=ghcr.io/openvario/ovbuild-container:latest bash ../ov-build.sh build
```

The checkout is mounted under the path it already has on the host, and the
build runs as the calling user. Both matter: Yocto stores absolute paths in
`tmp/` and in the sstate cache, so only an identical path lets a build inside
the container and one outside share them, and bitbake refuses to run as root
while everything it writes has to stay editable afterwards. `OV_CONTAINER_RUNTIME`
switches between docker and podman, `OV_CONTAINER_ARGS` adds further arguments,
and `--container ""` forces a host build even when the variable is set.

Only the bitbake calls go into the container. Checkout and packaging stay
outside, where git and the deploy directories are.

`deploy` picks up what the build produced and assembles the upgrade package:
the compressed SD card image, the first 2024 KiB of it as `bootsector.bin.gz`,
the recovery image `ov-recovery.itb`, and the two scripts `fw-upgrade.sh` and
`update-system-config.sh`. The layout matches what `fw-upgrade.sh` looks for on
the USB stick. The package is zipped to
`<deploy>/<OV_VERSION>/Upgrade-OV-<SHORT>-v<OV_VERSION>.zip`, and if a
publishing directory is configured, image and archive are copied there as well.

The image file name is not guessed: the image class writes it to `image_link`
next to the image, and that is what `deploy` reads. Short machine names such as
`CH70` or `AM70s` come from `SHORT_OV_MACHINE` in the machine configuration, so
a new machine needs no change here.

## Settings

Nothing in this directory contains a personal path, a private remote or a
publishing target. All of that comes from environment variables, which a small
wrapper outside the repository is meant to set:

| Variable | Meaning | Default |
| --- | --- | --- |
| `OV_REPO` | path of the checkout | the repository these scripts live in |
| `OV_REMOTE` | remote to fetch from | `origin` |
| `OV_BRANCH` | branch to build | `master` |
| `OV_CLONE_URL` | URL used if the checkout is missing | `https://github.com/OpenSoaring/OpenVario` |
| `OV_MACHINES` | machines, space separated, or `all` | `ov-ch70` |
| `OV_IMAGE` | image recipe | `openvario-image` |
| `OV_RECOVERY` | build the recovery images as well | `y` |
| `OV_DEPLOY_DIR` | where the upgrade packages go | `<repo>/../Deploy` |
| `OV_PUBLISH_DIR` | additional copy target, for instance a cloud folder | empty, nothing is published |
| `OV_MIN_IMAGE_MB` | smallest plausible image; below this the build counts as failed | `10` |

Command line options `--repo`, `--machines`, `--branch`, `--image` and
`--no-recovery` take precedence over the environment.

`all` expands to every machine that defines `SHORT_OV_MACHINE`. A machine
without it, such as the experimental `ov-cubieboard`, cannot produce a named SD
card image and is therefore left out.

The versions come from `meta-openvario/ov-versions.inc`, the same file bitbake
reads through `conf/distro/ovlinux.conf`.

## Wrapper outside the repository

`example-wrapper.sh` shows the intended shape: a few exports, then the call.
Copy it next to the checkout, fill in your own values, and keep it out of the
repository.
