# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r7"
RCONFLICTS:${PN}="opensoar-test "

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master " 

# OpenSoar Tag: v7.42.22.A
SRCREV = "40eb010adea0db1fef54eeea34c7e048861dae72"

BOOST_VERSION = "1.84.0"
BOOST_SHA256HASH = "cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454"

require opensoar.inc

