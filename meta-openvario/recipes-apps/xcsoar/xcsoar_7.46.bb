# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r7.46"

# The exact release (7.46) comes from VERSION.inc in the repository
# root; the file name only names the 7.46 series.  It has to match the
# SRCREV below.
require VERSION.inc
PV = "${XCSOAR_VERSION}"

# bitbake looks for the patches in xcsoar-${PV}/, which would stop to
# match with a release like 7.46.1; name the directory, so it keeps its
# precedence over files/ whatever the release is.
FILESEXTRAPATHS:prepend := "${THISDIR}/xcsoar-7.46:"
RCONFLICTS:${PN}="xcsoar-testing"

# SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=v7.46.x "

# Commit version for 7.46:
# SRCREV = "1998c3e492634ec056d3f01718c6c339a8e5b445"  # -> 7.46 (tag)
# -> 7.46 with the two fixes that followed the tag on v7.46.x: the
# MinGW build of the airspace warning test, and no multi-draw on
# PowerVR Rogue graphics.
SRCREV = "84898e40d417b6f6564d14e41cd85b53f10bb3fb"

# The 7.46 sources use boost 1.92 (build/libboost.mk); the hash is the
# one that file checks the tarball against.
BOOST_VERSION = "1.92.0"
BOOST_SHA256HASH = "5c1d40cb8e19adbf740a4ec2da35b3e58f3f5804b1dce44deb53df72193cbc6c"

# The OpenVario settings inside XCSoar, which XCSoar 7.46 does not have
# yet; the series of the 7.45 recipe, carried over to the 7.46 sources:
# calibrations, firmware upgrade, system backup, the program to start
# after boot and the display rotation kept across a reboot.
SRC_URI += " \
	file://0008-OV-move-the-sensor-and-touch-calibration-out-of-Open.patch \
	file://0009-OV-System-detect-an-OpenVario-read-the-image-name-an.patch \
	file://0010-OV-System-store-the-display-rotation-without-rotatin.patch \
	file://0011-DisplayConfigPanel-keep-the-orientation-on-an-OpenVa.patch \
	file://0012-DisplayConfigPanel-calibrate-the-touch-screen-on-an-.patch \
	file://0013-SystemdConfigPanel-the-OpenVario-system-functions-be.patch \
	file://0014-OpenVarioSystemWidget-start-the-firmware-upgrade-fro.patch \
	file://0015-OpenVarioSystemWidget-back-up-and-restore-the-whole-.patch \
	file://0016-OpenVario-remove-OpenVarioMenu-and-move-src-OV-to-sr.patch \
"

# Only for this image: XCSoar chooses the firmware image itself, puts
# it into data/images and quits with exit code 205 for ovmenu-ng.sh.
SRC_URI += "file://0017-OpenVario-choose-the-firmware-image-in-XCSoar-and-qu.patch \
	file://0018-OpenVarioSystemWidget-count-the-rows-without-the-upg.patch \
	file://0019-OpenVarioSystemWidget-let-the-cursor-keys-reach-the-.patch \
	file://0020-SystemdConfigPanel-say-why-a-service-could-not-be-st.patch \
	file://0021-OpenVario-stop-a-touch-calibration-nobody-can-finish.patch \
	file://0022-OpenVario-do-not-wake-the-USB-automount-without-a-st.patch"

require xcsoar.inc
