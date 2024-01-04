# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r14"
RCONFLICTS:${PN}="xcsoar"

SRCREV:pn-xcsoar-testing = "${AUTOREV}" 

SRC_URI = " \
   git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master \
"

inherit systemd

BOOST_VERSION = "1.82.0"
BOOST_SHA256HASH = "a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

require xcsoar.inc


do_compile:append() {
	oe_runmake output/UNIX/bin/OpenVarioMenu
}

do_install:append() {
	install -m755 ${S}/output/UNIX/bin/OpenVarioMenu ${D}${bindir}

}

