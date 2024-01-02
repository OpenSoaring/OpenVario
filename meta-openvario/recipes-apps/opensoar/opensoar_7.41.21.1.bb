# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r6"
### RCONFLICTS:${PN}="xcsoar xcsoar-testing"
RCONFLICTS:${PN}="xcsoar-testing"

### SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master    file://ovmenu-xcs.service" 

### 
SRC_URI = "git:///mnt/d/Projects/OpenSoaring/OpenSoar/.git/;protocol=file;branch=dev-branch    file://ovmenu-xcs.service"

# SRCREV = "${AUTOREV}"

# OpenSoar Tag: v7.41.21
SRCREV = "2e0851053275bf76588fb97a8d344d4e40061393"

BOOST_VERSION = "1.84.0"
BOOST_SHA256HASH = "cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454"

inherit systemd

require opensoar.inc


PACKAGES += "ovmenu-xcs"
RDEPENDS:ovmenu-xcs += " \
	${PN} \
	ovmenu-ng-skripts \
	autofs-config \
"
RCONFLICTS:ovmenu-xcs += "ovmenu-ng-autostart"
SYSTEMD_PACKAGES = "ovmenu-xcs"
SYSTEMD_SERVICE:ovmenu-xcs = "ovmenu-xcs.service"

do_compile:append() {
	oe_runmake output/UNIX/bin/OpenVarioMenu
}

do_install:append() {
	install -m755 ${S}/output/UNIX/bin/OpenVarioMenu ${D}${bindir}

	install -d ${D}${systemd_unitdir}/system
	install -m644 ${WORKDIR}/ovmenu-xcs.service ${D}${systemd_unitdir}/system
}

FILES:ovmenu-xcs += "${bindir}/OpenVarioMenu"

