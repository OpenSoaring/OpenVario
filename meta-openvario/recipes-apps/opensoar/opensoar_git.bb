# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r25.36"

# The version is set in VERSION.inc in the repository root, not by the
# name of this file, so a new OpenSoar test build changes SRCREV here
# and OPENSOAR_VERSION there, and nothing has to be renamed.
require VERSION.inc
PV = "${OPENSOAR_VERSION}"

# Each test version is a single commit on top of work25 that is
# kept as a tag, and the next test version is built without it, so the
# SRCREV of a test build leaves the branch later.  nobranch=1 lets the
# fetcher take it from the tag then, which the full clone also fetches.
SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work25;nobranch=1 " 
# SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work " 
SRCREV = "b1eb7d057d3120f522480b280a219cbbb92f6ced"


# dev branch is: boost 1.90:
BOOST_VERSION = "1.90.0"
BOOST_SHA256HASH = "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305"
                    
require opensoar.inc

