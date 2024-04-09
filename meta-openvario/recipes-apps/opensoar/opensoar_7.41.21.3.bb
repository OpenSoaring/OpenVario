# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r7"
RCONFLICTS:${PN}="opensoar-test "

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master " 
# SRCREV = "${AUTOREV}"

# OpenSoar Tag: v7.41.21.3
# ist noch nicht auf OpenSoaring/OPenSoar
# SRCREV = "2e0851053275bf76588fb97a8d344d4e40061393"

BOOST_VERSION = "1.84.0"
BOOST_SHA256HASH = "cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454"

require opensoar.inc

