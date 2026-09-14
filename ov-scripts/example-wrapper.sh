#!/bin/bash
# Template for a wrapper outside the repository.
#
# Copy this file next to the checkout, for example as ../ov-build.sh, put your
# own values in, and keep it out of the repository: it is the one place where
# private paths, remotes and publishing targets belong. Everything below the
# exports is the same for everyone and lives in ov-scripts/.
#
# The wrapper needs no execute bit either if it is started as "bash ov-build.sh".

set -e

# Where the checkout is. The default assumes the wrapper sits next to it.
export OV_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/OpenVario"

# Which remote and branch to build.
export OV_REMOTE="origin"
export OV_BRANCH="master"

# Which machines. "all" builds every machine the layer names.
export OV_MACHINES="ov-ch57 ov-ch70"

# Where the upgrade packages are assembled, and where the finished files are
# copied afterwards. Leave OV_PUBLISH_DIR unset to skip the copy.
export OV_DEPLOY_DIR="$(dirname "$OV_REPO")/Deploy"
# export OV_PUBLISH_DIR="/mnt/d/OneDrive/OpenSoar"

# Run bitbake in a container instead of on this host. Leave it unset to build
# directly, which is what a supported distribution allows.
# export OV_CONTAINER="ghcr.io/openvario/ovbuild-container:latest"
# export OV_CONTAINER_RUNTIME="docker"
# export OV_CONTAINER_ARGS=""

python3 "$OV_REPO/ov-scripts/ov.py" "${@:-all}"
