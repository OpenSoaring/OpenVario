# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r0"
RCONFLICTS:${PN}="xcsoar xcsoar-testing"

SRCREV:pn-xcsoar-august = "${AUTOREV}" 

# old SRC_URI = "git://github.com/August2111/XCSoar.git;protocol=git;branch=weglide-next "
# the current:
SRC_URI = "https://github.com/August2111/XCSoar.git;protocol=https;branch=august-main "

require xcsoar.inc

