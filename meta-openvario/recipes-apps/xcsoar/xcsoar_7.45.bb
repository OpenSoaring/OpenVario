# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r7.45.3"
RCONFLICTS:${PN}="xcsoar-testing"

# SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=v7.45.x "

# Commit version for 7.45:
# SRCREV = "5bbf804b54cb57416e9de6c3247ad637d4066710"  # -> 7.45
# SRCREV = "7320db6256b91b112cb66220a8e4611b962dd949"  # -> 7.45.1
# SRCREV = "a2449fdf1bb18ce57670734371a05e0ca10c7cdf"  # -> 7.45.2
# -> 7.45.3
SRCREV = "f18f5f0ca1055767e5fa215a2903d32085bbd321"

# dev branch is: boost 1.90:
BOOST_VERSION = "1.90.0"
BOOST_SHA256HASH = "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305"

# The OpenVario settings inside XCSoar, as proposed for XCSoar 7.46:
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
	file://0018-OpenVarioSystemWidget-count-the-rows-without-the-upg.patch"

require xcsoar.inc
