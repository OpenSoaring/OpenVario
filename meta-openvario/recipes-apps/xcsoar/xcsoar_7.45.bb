# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r7.45.2"
RCONFLICTS:${PN}="xcsoar-testing"

# SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=v7.45.x "

# Commit version for 7.45:
# SRCREV = "5bbf804b54cb57416e9de6c3247ad637d4066710"  # -> 7.45
# SRCREV = "7320db6256b91b112cb66220a8e4611b962dd949"  # -> 7.45.1
# SRCREV = "a2449fdf1bb18ce57670734371a05e0ca10c7cdf"  # -> 7.45.2
SRCREV = "5512bed3946d6baceeb0b5d6d94404c30e3e35b6"

# dev branch is: boost 1.90:
BOOST_VERSION = "1.90.0"
BOOST_SHA256HASH = "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305"

require xcsoar.inc
