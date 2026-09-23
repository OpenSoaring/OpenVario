#!/bin/sh
#
# set-main.sh - select the main application the OpenVario starts after boot.
#
# The boot menu reads the variable "main_app" from /boot/config.uEnv and starts
# /usr/bin/<main_app>. This script rewrites that variable in a controlled way:
# it refuses names that are not installed, keeps the rest of the file untouched,
# handles a read-only /boot and CRLF line endings, and offers a reboot at the end
# because the change only takes effect on the next start.
#
# Usage:  set-main.sh <application>      e.g.  set-main.sh OpenSoar
#                                              set-main.sh xcsoar
#
# Written for the BusyBox shell of the OpenVario image, so it stays POSIX sh.

CONFIG=/boot/config.uEnv
BINDIR=/usr/bin

usage() {
    echo "Usage: $(basename "$0") <application>" >&2
    echo "Sets main_app in $CONFIG to the given program from $BINDIR." >&2
    exit 2
}

die() {
    echo "Error: $*" >&2
    exit 1
}

[ $# -eq 1 ] || usage
APP=$1

case "$APP" in
    ""|*/*|*" "*) die "'$APP' is not a plain program name." ;;
esac

[ -x "$BINDIR/$APP" ] || die "'$APP' is not installed: $BINDIR/$APP does not exist or is not executable."
[ -f "$CONFIG" ] || die "$CONFIG not found - is /boot mounted?"
[ "$(id -u)" -eq 0 ] || die "must be run as root."

# Show what we are about to replace so the user sees the previous state.
CURRENT=$(sed -n 's/^main_app=//p' "$CONFIG" | tr -d '\r' | head -n 1)
if [ "$CURRENT" = "$APP" ]; then
    echo "main_app is already set to '$APP' - nothing to do."
    exit 0
fi

# /boot is a FAT partition that some images mount read-only; remount it
# writable for the duration of the change and put it back afterwards.
REMOUNTED=0
if ! touch "$CONFIG" 2>/dev/null; then
    mount -o remount,rw /boot || die "cannot remount /boot read-write."
    REMOUNTED=1
fi

# Replace the existing line, or append it if the file has none. The trailing
# "\r" handling keeps a CRLF file consistent instead of mixing line endings.
CR=$(printf '\r')
if grep -q '^main_app=' "$CONFIG"; then
    if grep -q "^main_app=.*$CR\$" "$CONFIG"; then
        sed -i "s/^main_app=.*/main_app=$APP$CR/" "$CONFIG"
    else
        sed -i "s/^main_app=.*/main_app=$APP/" "$CONFIG"
    fi
else
    echo "main_app=$APP" >> "$CONFIG"
fi
sync

[ $REMOUNTED -eq 1 ] && mount -o remount,ro /boot

echo "main_app changed from '${CURRENT:-<unset>}' to '$APP' in $CONFIG."
echo "The change takes effect on the next boot."

printf "Reboot now? [y/N] "
read -r ANSWER
case "$ANSWER" in
    y|Y|yes|YES|j|J)
        echo "Rebooting ..."
        reboot
        ;;
    *)
        echo "Not rebooting. Run 'reboot' when ready."
        ;;
esac