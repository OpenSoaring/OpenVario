# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r7.46"
RCONFLICTS:${PN}="xcsoar xcsoar-preview"

# XCSoar master on the way to 7.46 (7 October 2026)
SRCREV:pn-xcsoar-testing = "e2d7f7bc15d64e0430980c721be4a3f57286b141"

SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "

# master builds with boost 1.92; the hash is the one in master's
# build/libboost.mk
BOOST_VERSION = "1.92.0"
BOOST_SHA256HASH = "5c1d40cb8e19adbf740a4ec2da35b3e58f3f5804b1dce44deb53df72193cbc6c"

# The OpenVario settings inside XCSoar, as proposed for XCSoar 7.46
# (pull request "openvario-settings"): calibrations, firmware upgrade,
# system backup, the program to start after boot and the display
# rotation kept across a reboot.  The last patch removes OpenVarioMenu,
# which is why this recipe no longer builds it.  The directory
# xcsoar-testing/ also holds a copy of 0007 whose context lines fit
# master; it takes precedence over the one in files/.
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
	file://0019-OpenVarioSystemWidget-let-the-cursor-keys-reach-the-.patch"

require xcsoar.inc
