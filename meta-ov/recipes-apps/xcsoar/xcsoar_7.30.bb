# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

## 
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master "

## SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;tag=v${PV} "

# Commit version for 7.30
SRCREV = "b32faf31a537471c6863efffe0cb1e0a90a598e4"

### # Commit version for 7.29
### SRCREV = "4b9c0b048ba250526c7f504f7ff79dbab8c85193"

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require xcsoar.inc
