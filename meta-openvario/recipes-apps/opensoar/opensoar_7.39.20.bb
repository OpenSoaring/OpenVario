# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r1"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/August2111/OpenSoar.git;protocol=https;branch=opensoar-dev "

###   # Commit version for 7.39.19
###   SRCREV = "01479838c90375051ca833d6a22f97c3a3f18be2"
# Commit version for 7.39.20 - in the moment only dev_branch
SRCREV = "6ccbded36ce094cdfba583e9472125601e6c0a36"
SRCREV = "0267a87fa4d1930b5c52308f882f8ac704254b00"
SRCREV = "1e07f8d7f51ac16f8576c8d74529d9012b6dd368"
SRCREV = "393a47f2b79b1f863ab1bf6ca055dc85daf853d4"
# not on server: SRCREV = "bc71974d997cd241f7efdbe3b8bcdb388bb2e1b5"

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require opensoar.inc
