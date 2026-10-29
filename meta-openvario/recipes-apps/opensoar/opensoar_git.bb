# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r27.2"

# The version is set in VERSION.inc in the repository root, not by the
# name of this file, so a new OpenSoar test build changes SRCREV here
# and OPENSOAR_VERSION there, and nothing has to be renamed.
require VERSION.inc
PV = "${OPENSOAR_VERSION}"

# This branch (work-ov) builds the development line of OpenSoar, work,
# which heads for 7.47.27.  Each test version is a single commit on top
# of work that is kept as a tag, and the next test version is built
# without it, so the SRCREV of a test build leaves the branch later.
# nobranch=1 lets the fetcher take it from the tag then, which the full
# clone also fetches.  The 7.46 line is built by work-ov26.
SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work;nobranch=1 " 
# OpenSoar 7.47.27.t04 (the state of 7.46.26 on the development line):
# SRCREV = "aeeb8a91ae00436e83d1d334aa65715287bc83eb"
# OpenSoar 7.47.27.t05 (the same state as a new test version):
SRCREV = "a2eb6796cfd6d52b348ddfcbabaa21a2603ee4e0"


# The 7.46 sources use boost 1.92 (build/libboost.mk); the hash is the
# one that file checks the tarball against.
BOOST_VERSION = "1.92.0"
BOOST_SHA256HASH = "5c1d40cb8e19adbf740a4ec2da35b3e58f3f5804b1dce44deb53df72193cbc6c"
                    
require opensoar.inc

