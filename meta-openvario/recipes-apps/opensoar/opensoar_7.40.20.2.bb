# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r2"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

### 
### SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master"
### 
### 
SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;tag=v7.40.20.2"
SRCREV = "${AUTOREV}"

# OpenSoar Tag: v7.40.20.2
# SRCREV = "2e0851053275bf76588fb97a8d344d4e40061393"


BOOST_VERSION = "1.83.0"
BOOST_SHA256HASH = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e"

require opensoar.inc
