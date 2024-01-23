# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r2"
RCONFLICTS:${PN}="opensoar"

### SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=master"
### OpenSoar Tag: v7.41.21
###  SRCREV = "2e0851053275bf76588fb97a8d344d4e40061393"

SRC_URI = "git:///mnt/d/Projects/OpenSoaring/OpenSoar/.git/;protocol=file;branch=dev-branch "
SRCREV = "${AUTOREV}"


BOOST_VERSION = "1.84.0"
BOOST_SHA256HASH = "cc4b893acf645c9d4b698e9a0f08ca8846aa5d6c68275c14c3e7949c24109454"

require opensoar.inc
