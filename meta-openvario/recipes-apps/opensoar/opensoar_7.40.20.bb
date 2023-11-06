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

# Commit version for 7.40.20 - in the moment only dev_branch

BOOST_VERSION = "1.83.0"
BOOST_SHA256HASH = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e"

require opensoar.inc
