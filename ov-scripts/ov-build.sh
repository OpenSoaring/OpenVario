#!/bin/bash

BRANCH=warrior
BRANCH=thud
# BRANCH=jethro
BRANCH=dev-branch

CHECKOUT="y"
if [[ "$CHECKOUT" == "y" ]]; then
  SCRIPT_PATH=$(dirname "$(readlink -e "$0")")
  echo "SCRIPT_PATH = $SCRIPT_PATH"
  $SCRIPT_PATH/git-checkout.sh
fi 


# cd poky 

# export BBPATH=/workdir/git-_$BRANCH/_$BRANCH
# BBPATH=/workdir/git-_$BRANCH/_$BRANCH

### TEMPLATECONF=meta-openvario/conf source oe-init-build-env .

# cd git-$BRANCH 
cd OpenVario

# /home/august2111/OpenVario/OpenVario/

## TOPDIR=$(pwd)
## export TOPDIR=$TOPDIR

# TEMPLATECONF=meta-openvario/conf source oe-init-build-env ../_$BRANCH
# TEMPLATECONF=meta-ov/conf source oe-init-build-env ../_$BRANCH
# TEMPLATECONF=meta-ov/conf
# export TEMPLATECONF=$TEMPLATECONF
# 
source openembedded-core/oe-init-build-env .
# 
# source openembedded-core/oe-init-build-env ../_$BRANCH
## this was the best before: TEMPLATECONF=$TOPDIR/meta-ov/conf source openembedded-core/oe-init-build-env ../_$BRANCH
# without cd:
# TEMPLATECONF=git-$BRANCH/meta-openvario/conf source git-$BRANCH/oe-init-build-env _$BRANCH

# ls -l

# PATH=$PATH:/workdir/git-_$BRANCH/bitbake/bin
# echo $PATH


export MACHINE=openvario-57-lvds

echo  "BRANCH   = $BRANCH"
echo  "MACHINE  = $MACHINE"
echo  "TOPDIR   = $TOPDIR"
echo  "TOPDIR   = ${TOPDIR}"
echo  "CurrDir  = $(pwd)"


# wic list images

### read -p "Stop until keypressed: " INPUT
### 
### if [[ "$INPUT" == "" ]];
### then
###   INPUT="j"
### fi
### echo "INPUT     = $INPUT"


TIMEOUT=2
DIALOG_TEXT="Building OpenSoar ... \\n"
DIALOG_TEXT="$DIALOG_TEXT BRANCH   = $BRANCH\\n"
DIALOG_TEXT="$DIALOG_TEXT MACHINE  = $MACHINE\\n"
DIALOG_TEXT="$DIALOG_TEXT CurrDir  = $(pwd)\\n"
DIALOG_TEXT="$DIALOG_TEXT ======================\\n"
DIALOG_TEXT="$DIALOG_TEXT Press [ESC] cancel"
DIALOG_TEXT="$DIALOG_TEXT "

DIALOG_CANCEL=1 dialog --nook --nocancel --pause "$DIALOG_TEXT" 20  80 $TIMEOUT 2>&1

case $? in
    0) INPUT="y";;
    *) INPUT="n";;
esac

if [[ "$INPUT" == "y" ]]; then

# IMAGE=openvario-image
# IMAGE=openvario-image-testing
# IMAGE=ov-recover-image
# IMAGE=ov-recover-initramfs
# IMAGE=openvario-recovery-initramfs
# IMAGE=openvario-recovery-# image
# bitbake $IMAGE

OPENVARIO_IMAGE="y"
if [[ "$OPENVARIO_IMAGE" == "y" ]]; then

#=====================================================
# IMAGE=openvario-image-thud
# IMAGE=openvario-image-testing
IMAGE=openvario-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""
##                machines = ['openvario-7-AM070-DS2']
##                machines = ['openvario-7-PQ070']
##                machines = ['openvario-7-CH070']
##                machines = ['openvario-7-CH070']
##                machines = ['openvario-7-CH070']
##                machines = ['openvario-57-lvds']
#=====================================================
export MACHINE=openvario-7-CH070
IMAGE=openvario-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

#=====================================================
export MACHINE=openvario-7-PQ070
IMAGE=openvario-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

#=====================================================
export MACHINE=openvario-7-AM070-DS2
IMAGE=openvario-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

#=====================================================
export MACHINE=openvario-43-rgb
IMAGE=openvario-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

#=====================================================
fi

export MACHINE=openvario-57-lvds
RECOVERY_INITRAMFS="y"
if [[ "$RECOVERY_INITRAMFS" == "y" ]]; then
IMAGE=openvario-recovery-initramfs
# old: IMAGE=ov-recover-initramfs
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

fi

RECOVERY_IMAGE="y"
if [[ "$RECOVERY_IMAGE" == "y" ]]; then
IMAGE=openvario-recovery-image
# old: IMAGE=ov-recover-image
echo "bitbake $IMAGE"
echo "============================"
echo ""
bitbake $IMAGE
echo ""

fi
fi

export MACHINE=

# chmod -R 757 ./ov-scripts
# cd ..
# chmod -R 757 ./OpenVario/ov-scripts
