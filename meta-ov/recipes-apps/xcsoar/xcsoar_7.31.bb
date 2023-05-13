# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

## 
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "
## SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;tag=v${PV} "

# Commit version for 7.31
SRCREV = "83e6916ec9fd9b4d16abab4efb6712a90d773a2f"

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require xcsoar.inc
