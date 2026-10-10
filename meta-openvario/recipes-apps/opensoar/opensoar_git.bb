# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r25.24"

# The version is set in VERSION.inc in the repository root, not by the
# name of this file, so a new OpenSoar test build changes SRCREV here
# and OPENSOAR_VERSION there, and nothing has to be renamed.
require VERSION.inc
PV = "${OPENSOAR_VERSION}"

SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work-7.45.25 " 
# SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work " 
SRCREV = "91fe63027ef4d1a81f7a90bf2c300698d3d168be"


# dev branch is: boost 1.90:
BOOST_VERSION = "1.90.0"
BOOST_SHA256HASH = "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305"
                    
require opensoar.inc

