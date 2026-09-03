# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR = "r12"

S = "${WORKDIR}/git"

inherit systemd

SRC_URI = "git://github.com/Openvario/sensord.git;protocol=https;branch=master"
SRCREV = "c6e07fdf3af6395ad6736363e1f60b7ff20bfc77"

require sensord.inc
