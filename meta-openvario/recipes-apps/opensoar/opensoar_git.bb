# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r26.3"

# The version is set in VERSION.inc in the repository root, not by the
# name of this file, so a new OpenSoar test build changes SRCREV here
# and OPENSOAR_VERSION there, and nothing has to be renamed.
require VERSION.inc
PV = "${OPENSOAR_VERSION}"

# Each test version is a single commit on top of work26 that is
# kept as a tag, and the next test version is built without it, so the
# SRCREV of a test build leaves the branch later.  nobranch=1 lets the
# fetcher take it from the tag then, which the full clone also fetches.
SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work26;nobranch=1 " 
# SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work " 
# OpenSoar 7.46.26.t01 (the first test version of the 7.46 line):
# SRCREV = "13d2912327da13b77448eefecacf3b0163816ed9"
# OpenSoar 7.46.26.t02 (the log book directly in the data directory):
# SRCREV = "ed60dbcbc92ff274e57033d677f4e8f0301c09b6"
# OpenSoar 7.46.26.t03 (cleaned history, news and add-on list):
SRCREV = "f76756a9b2aa2e40f1fd5c9ff2759f8b1f845d3f"


# The 7.46 sources use boost 1.92 (build/libboost.mk); the hash is the
# one that file checks the tarball against.
BOOST_VERSION = "1.92.0"
BOOST_SHA256HASH = "5c1d40cb8e19adbf740a4ec2da35b3e58f3f5804b1dce44deb53df72193cbc6c"
                    
require opensoar.inc

