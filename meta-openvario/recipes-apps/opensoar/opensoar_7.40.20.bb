# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r1"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=opensoar-dev "

##   ###   # Commit version for 7.39.19
##   ###   SRCREV = "01479838c90375051ca833d6a22f97c3a3f18be2"
# Commit version for 7.40.20
SRCREV = "7bae2e0eb010af059e1d31fc4bb687c24050b6fa"

BOOST_VERSION = "1.83.0"
BOOST_SHA256HASH = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e"

require opensoar.inc
