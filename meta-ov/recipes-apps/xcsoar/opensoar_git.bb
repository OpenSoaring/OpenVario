# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/August2111/XCSoar.git;protocol=https;branch=dev-branch "
SRCREV:pn-opensoar = "${AUTOREV}" 
# SRCREV = "???"

EXTRA_CXXFLAGS = "-Wno-empty-body"
export EXTRA_CXXFLAGS

require opensoar.inc
