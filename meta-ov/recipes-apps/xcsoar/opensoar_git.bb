# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r2"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/August2111/OpenSoar.git;protocol=https;branch=dev-branch "
SRCREV:pn-opensoar = "${AUTOREV}" 

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require opensoar.inc
