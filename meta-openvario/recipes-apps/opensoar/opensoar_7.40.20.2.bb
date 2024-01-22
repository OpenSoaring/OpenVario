# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r2"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
# RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master"

# OpenSoar Tag: v7.40.20.2
SRCREV = "575cc1dfde9d3b56bcd67fc8d16e83e41c09bcdc"


BOOST_VERSION = "1.83.0"
BOOST_SHA256HASH = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e"

require opensoar.inc


# no correct interpretation with AUTOREV:
## SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=dev-branch;tag=refs/tags/v7.40.20.2"
## SRCREV = "${AUTOREV}"
