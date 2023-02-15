# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/August2111/XCSoar.git;protocol=https;branch=dev-branch "
SRCREV:pn-opensoar = "${AUTOREV}" 

BOOST_VERSION = "1.81.0"
BOOST_SHA256HASH = "71feeed900fbccca04a3b4f2f84a7c217186f28a940ed8b7ed4725986baf99fa"

require opensoar.inc
