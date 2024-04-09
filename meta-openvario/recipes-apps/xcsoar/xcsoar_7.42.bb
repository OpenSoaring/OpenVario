# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r1"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "

# Commit version for 7.42:
# commit id from Max:
# SRCREV = "8b9032b5fbaca16575e2ace4df372883d14db507"
# commit id from XCSoar/XCSoar(?):
SRCREV = "9ee29aa606f7ebc44604b51c966882a3b9d7c953"

BOOST_VERSION = "1.84.0"
BOOST_SHA256HASH = "cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454"

require xcsoar.inc
