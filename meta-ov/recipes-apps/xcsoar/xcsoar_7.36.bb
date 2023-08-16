# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r1"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "

# Commit version for 7.36:
SRCREV = "a626d3efe0fdc723a855b1db45665e0218e34962"

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require xcsoar.inc