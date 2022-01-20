# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r13"
RCONFLICTS:${PN}="xcsoar"

SRCREV:pn-xcsoar-testing = "${AUTOREV}" 


BOOST_VERSION = "1.81.0"
BOOST_SHA256HASH = "71feeed900fbccca04a3b4f2f84a7c217186f28a940ed8b7ed4725986baf99fa"
SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=master \
	file://ovmenu-x.service \
"

inherit systemd

require xcsoar.inc

PACKAGES += "ovmenu-x"
RDEPENDS:ovmenu-x += " \
	${PN} \
	ovmenu-ng-skripts \
	autofs-config \
"
RCONFLICTS:ovmenu-x += "ovmenu-ng-autostart"
SYSTEMD_PACKAGES = "ovmenu-x"
SYSTEMD_SERVICE:ovmenu-x = "ovmenu-x.service"

do_compile:append() {
	oe_runmake output/UNIX/bin/OpenVarioMenu
}

do_install:append() {
	install -m755 ${S}/output/UNIX/bin/OpenVarioMenu ${D}${bindir}

	install -d ${D}${systemd_unitdir}/system
	install -m644 ${WORKDIR}/ovmenu-x.service ${D}${systemd_unitdir}/system
}

FILES:ovmenu-x += "${bindir}/OpenVarioMenu"
