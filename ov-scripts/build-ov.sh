#!/bin/bash

# cd poky
#TEMPLATECONF=meta-openvario/conf source oe-init-build-env build
# source openembedded-core/oe-init-build-env ~/OpenVario/build
# source openembedded-core/oe-init-build-env ./_build
source openembedded-core/oe-init-build-env .

## 
# # # 
# bitbake -c cleanall linux-firmware
# # # 
# bitbake -c listtasks linux-firmware
# 
# 

###CMD_LINE="bitbake -c cleanall xcsoar-profile"
###echo "build-ov.sh: ${CMD_LINE}"
###${CMD_LINE}
######  # bitbake -c cleanall xcsoar-profile

# bitbake -c compile linux-firmware
# bitbake -c install linux-firmware
# bitbake -c package_write_ipk linux-firmware
# # # 
# bitbake -c unpack linux-firmware
## bitbake -c cleanall variod-testing_git
## bitbake -c compile variod-testing_git
# bitbake -c compile variod

# # # 
# bitbake -c cleanall linux-mainline
# bitbake -c install linux-mainline
# bitbake -c package_write_ipk linux-mainline

## 
# echo "build-ov.sh: bitbake $1"
### bitbake $1

CMD_LINE="bitbake $1"
echo "build-ov.sh: ${CMD_LINE}"
${CMD_LINE}

