# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master \
"

SRCREV = "db71cad5aa2c037be12a099c671195c3ec1f34c6"

# TODO remove this after 7.25 has been released with https://github.com/XCSoar/XCSoar/commit/7ce3070fee3a140b6a4d9437a2cfe9854f78abfe
EXTRA_CXXFLAGS = "-Wno-empty-body"
export EXTRA_CXXFLAGS

BOOST_VERSION = "1.80.0"
BOOST_SHA256HASH = "1e19565d82e43bc59209a168f5ac899d3ba471d55c7610c677d4ccf2c9c500c0"

require xcsoar.inc