# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/larus-breeze/XCSoar-Larus.git;protocol=https;branch=larus "
SRCREV:pn-xcsoar-larus = "${AUTOREV}" 
# SRCREV = "???"

EXTRA_CXXFLAGS = "-Wno-empty-body"
export EXTRA_CXXFLAGS

require xcsoar.inc
