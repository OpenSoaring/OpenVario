#!/bin/bash
# Check, and optionally install, what a build needs on this host.
#
#   bash ov-scripts/setup-host.sh              # report only
#   bash ov-scripts/setup-host.sh --install    # report and install with apt
#
# Two things are looked at. First the packages Yocto asks for on a Debian or
# Ubuntu host; they are listed here because no file in the tree names them.
# Second, and more usefully, every tool in HOSTTOOLS of the oe-core that this
# checkout carries: bitbake refuses to start when one of them is missing, and
# the list grows between releases, so reading it from the tree keeps this
# script correct for kirkstone and scarthgap alike.
#
# The script is only useful for a build directly on the host. Inside a
# container the image brings its own tools.

set -u

INSTALL=n
[ "${1:-}" = "--install" ] && INSTALL=y

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/.." && pwd)
conf="$repo/openembedded-core/meta/conf/bitbake.conf"

# Packages Yocto documents for Debian and Ubuntu hosts, plus the four that
# cover the tools most often missing after a fresh WSL installation. The Yocto
# manual still names liblz4-tool here, but that is a transitional package which
# releases after 24.04 dropped; lz4 is what carries the binaries now.
BASE_PACKAGES="gawk wget git diffstat unzip texinfo gcc build-essential \
chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
iputils-ping python3-git python3-jinja2 python3-subunit zstd lz4 file \
locales libacl1"

# Which package provides a tool, where the name differs. Everything not listed
# here is assumed to come with the base packages above.
tool_package() {
    case "$1" in
        chrpath)              echo chrpath ;;
        cpio)                 echo cpio ;;
        lz4c)                 echo lz4 ;;
        zstd|pzstd|unzstd)    echo zstd ;;
        diffstat)             echo diffstat ;;
        makeinfo)             echo texinfo ;;
        rpcgen)               echo rpcsvc-proto ;;
        g++|gcc|cpp|ld|nm|ar) echo build-essential ;;
        gawk|awk)             echo gawk ;;
        file)                 echo file ;;
        wget)                 echo wget ;;
        git)                  echo git ;;
        perl)                 echo perl ;;
        python3)              echo python3 ;;
        xz)                   echo xz-utils ;;
        *)                    echo "" ;;
    esac
}

echo "Checkout : $repo"

if [ ! -f "$conf" ]; then
    echo "openembedded-core is not checked out, so HOSTTOOLS cannot be read."
    echo "Only the documented base packages are considered."
    tools=""
else
    # HOSTTOOLS is assigned over several continued lines; collect them all.
    # Lines containing ${@ hold python expressions - they add tools only for
    # testimage and would otherwise contribute their own keywords to the list.
    tools=$(awk '
        /^HOSTTOOLS[ ]*\+?=/ { collecting = 1 }
        collecting {
            line = $0
            if (line ~ /\$\{@/) { if ($0 !~ /\\$/) collecting = 0; next }
            sub(/^HOSTTOOLS[ ]*\+?=[ ]*"/, "", line)
            gsub(/\\$/, "", line)
            gsub(/"/, "", line)
            print line
            if ($0 !~ /\\$/) collecting = 0
        }
    ' "$conf" | tr ' ' '\n' | grep -E '^[a-zA-Z][a-zA-Z0-9_.+-]*$' | sort -u)
    echo "HOSTTOOLS: $(echo "$tools" | wc -l) tools required by this oe-core"
fi

missing=""
packages=""
for tool in $tools; do
    command -v "$tool" >/dev/null 2>&1 && continue
    missing="$missing $tool"
    pkg=$(tool_package "$tool")
    [ -n "$pkg" ] && packages="$packages $pkg"
done

echo ""
if [ -z "$missing" ]; then
    echo "All required tools are present."
else
    echo "Missing tools:$missing"
    unknown=""
    for tool in $missing; do
        [ -z "$(tool_package "$tool")" ] && unknown="$unknown $tool"
    done
    [ -n "$unknown" ] && echo "No package mapping known for:$unknown"
fi

packages=$(echo "$BASE_PACKAGES $packages" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')

# apt installs nothing at all when one name on the command line is unknown or
# has no candidate, so a single package that a release has dropped keeps every
# other one from being installed as well. Rather than judge the names here,
# ask apt in a simulation and drop whatever it complains about: it knows about
# virtual packages and providers, which a look at apt-cache policy does not.
if command -v apt-get >/dev/null 2>&1; then
    dropped=""
    for _attempt in 1 2 3; do
        # shellcheck disable=SC2086
        bad=$(apt-get install -y --simulate $packages 2>&1 >/dev/null | sed -n \
            -e "s/.*Unable to locate package \([^ ]*\).*/\1/p" \
            -e "s/.*Package '\([^']*\)' has no installation candidate.*/\1/p" \
            | sort -u)
        [ -z "$bad" ] && break
        for pkg in $bad; do
            packages=$(echo " $packages " | sed "s/ $pkg / /g")
            dropped="$dropped $pkg"
        done
    done
    packages=$(echo "$packages" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    [ -n "$dropped" ] && echo "" && \
        echo "Not offered by this release, left out:$dropped"
fi

echo ""
echo "Packages to install:"
echo "  sudo apt-get install -y $packages"

if [ "$INSTALL" = "y" ]; then
    echo ""
    echo "Installing ..."
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install -y $packages
    # Releases after 24.04 no longer ship lz4c, while HOSTTOOLS still asks for
    # it. The binary it used to be is lz4 under another name, so a link is the
    # accepted answer and is made here rather than left as homework.
    if ! command -v lz4c >/dev/null 2>&1 && command -v lz4 >/dev/null 2>&1; then
        echo ""
        echo "lz4c is not part of the lz4 package on this release; linking it to lz4."
        sudo ln -sf "$(command -v lz4)" /usr/bin/lz4c
    fi

    echo ""
    echo "Checking again:"
    still=""
    for tool in $tools; do
        command -v "$tool" >/dev/null 2>&1 || still="$still $tool"
    done
    if [ -z "$still" ]; then
        echo "  all required tools are present now."
    else
        echo "  still missing:$still"
        echo "  Look for the package with: apt-file search bin/<tool>"
    fi
fi
