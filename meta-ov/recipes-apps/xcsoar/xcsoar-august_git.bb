# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r0"
RCONFLICTS:${PN}="xcsoar xcsoar-testing"

SRCREV:pn-xcsoar-august = "${AUTOREV}" 
# SRCREV = "db71cad5aa2c037be12a099c671195c3ec1f34c6"

# old SRC_URI = "git://github.com/August2111/XCSoar.git;protocol=git;branch=weglide-next "
# the current:
SRC_URI = "git://github.com/August2111/XCSoar.git;protocol=https;branch=august-main "
# SRC_URI[sha256sum] = "eb7da6386c9528526a7b219d26c29cb3a2d86dd585e025075fb650c8f24c23cd"

BOOST_VERSION = "1.81.0"
BOOST_SHA256HASH = "71feeed900fbccca04a3b4f2f84a7c217186f28a940ed8b7ed4725986baf99fa"

require xcsoar.inc

