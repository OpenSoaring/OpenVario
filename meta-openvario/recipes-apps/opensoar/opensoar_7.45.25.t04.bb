# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r25.07"

require openvario.inc

# SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work " 
SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work-7.45.25 " 
# SRC_URI = "git://github.com/OpenSoaring/OpenSoar.git;protocol=https;branch=work " 
# v7.45.25: /  # (v7.45.25.t04):
SRCREV = "d1cc91484f80e184c1873c82e026cef4c90c5fc2"


# dev branch is: boost 1.90:
BOOST_VERSION = "1.90.0"
BOOST_SHA256HASH = "49551aff3b22cbc5c5a9ed3dbc92f0e23ea50a0f7325b0d198b705e8ee3fc305"
                    
require opensoar.inc

