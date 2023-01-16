# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/larus_breeze/XCSoar-Larus.git;protocol=https;branch=larus \"

SRCREV = "6ce0396567f1aaea98619dca77db93276dd2382e"

EXTRA_CXXFLAGS = "-Wno-empty-body"
export EXTRA_CXXFLAGS

require xcsoar.inc
