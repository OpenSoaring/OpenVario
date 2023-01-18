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

require xcsoar.inc

