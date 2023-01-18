#!/bin/bash

SHORT_MACHINE="OV-AM70_2"
TAG_VERSION="3.3.1"

IMAGE_NAME="$SHORT_MACHINE-$TAG_VERSION-current.img.gz"

BASIC_NAME="OpenVario-linux"

# BUILD_NAME="openvario-image"
# BUILD_NAME="openvario-image-testing"
BUILD_NAME="ov-august"

IPK_NAME="glibc-ipk"

VERSION_NAME="22052"
# VERSION_NAME="current"

MACHINE_NAME="openvario-7-AM070-DS2"
# MACHINE_NAME="openvario-57-lvds"

EXTENSION="rootfs.img"

IMAGE_NAME="$BASIC_NAME-$BUILD_NAME-$IPK_NAME-$VERSION_NAME-$MACHINE_NAME.$EXTENSION"
IMAGE_NAME="OpenVario-linux-openvario-image-glibc-ipk-current-openvario-7-AM070-DS2.rootfs.img"
IMAGE_NAME="OpenVario-linux-openvario-image-glibc-ipk-current-openvario-57-lvds.rootfs.img"
# IMAGE_NAME="OpenVario-linux-openvario-image-testing-glibc-ipk-current-openvario-57-lvds.rootfs.img"
# IMAGE_NAME="OpenVario-linux-ov-august-glibc-ipk-22033-openvario-57-lvds.rootfs.img"
# IMAGE_NAME="OpenVario-linux-ov-august-glibc-ipk-current-openvario-57-lvds.rootfs.img"

# IMAGE_NAME="last-ov"
# IMAGE_NAME="OpenVario-linux-openvario-image-glibc-ipk-current-openvario-57-lvds.rootfs.img"
# IMAGE_NAME="OpenVario-linux-openvario-image-testing-glibc-ipk-current-openvario-57-lvds.rootfs.img"
# IMAGE_NAME="2022-01-05_OpenVario-linux-openvario-image-glibc-ipk-22005-openvario-57-lvds.rootfs.img"

IMAGE_NAME="OV-3.0.1-6-CB2-AM70_2.img"
# IMAGE_NAME="OV-3.0.1-6-CB2-CH70.img"

# python:
#if len(sys.argv) > 1:
#    ov_type = sys.argv[1]
#    if ov_type == 'AM70':
#                machines = ['openvario-7-AM070-DS2']
#    elif ov_type == 'PQ70':
#                machines = ['openvario-7-PQ070']
#    elif ov_type == 'TX70':
#                machines = ['openvario-7-CH070']
#    elif ov_type == 'CH70':
#                machines = ['openvario-7-CH070']
#    elif ov_type == 'CH70':
#                machines = ['openvario-7-CH070']
#    elif ov_type == 'CH57':
#                machines = ['openvario-57-lvds']
#    else:
#                machines = [ov_type]
#else:
#    # only one!
#    machines = ['openvario-7-CH070']


# DATE=$(date +%y%j)
# echo "Date Version: $DATE"
# IMAGE_NAME="$SHORT_MACHINE-$TAG_VERSION-$DATE.img.gz"

if [ $USER == pokyuser ]; then
  echo "USER: pokyuser!!!!!!!!!!!!!!!!!!!"
  WRITE_TARGET=/dev/sda
  TARGET=${WRITE_TARGET}
  # IMAGE_DIR="/home/august/Projects/OpenVario/tmp/deploy/images/$MACHINE_NAME"
  IMAGE_DIR=""
elif [ $USER == august ]; then
  echo "USER: august!!!!!!!!!!!!!!!!!!!"
  WRITE_TARGET=/dev/mmcblk0
  TARGET=${WRITE_TARGET}p
#  WRITE_TARGET=/dev/sdc
#  TARGET=${WRITE_TARGET}
  IMAGE_DIR=poky/build/
  IMAGE_DIR=deploy/

  IMAGE_DIR=poky/build/
  IMAGE_DIR=$(pwd)/
#  IMAGE_DIR="$(pwd)/tmp/deploy/images/$MACHINE_NAME/"

else
  echo "UNKNOWN user: $USER!!!!!!!!!!!!!!!!!!!"
  
  exit
fi
# 

echo "TARGET: ${TARGET} / ${WRITE_TARGET} " 
umount ${TARGET}1
umount ${TARGET}2
# wrong? if [ -f "${TARGET}3" ]; then
umount ${TARGET}3

if [ -f $IMAGE_DIR$IMAGE_NAME.gz ]; then

echo "write '$IMAGE_NAME' to SD (${WRITE_TARGET})"
echo "==================================="
WRITE_CMD="gzip -cfd $IMAGE_DIR$IMAGE_NAME.gz | sudo dd of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync"
# WRITE_CMD="dd if=$IMAGE_DIR$IMAGE_NAME of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync"

echo "$WRITE_CMD"
# ??? "$WRITE_CMD"
# gzip -cfd $IMAGE_DIR$IMAGE_NAME.gz | sudo dd of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync
sudo dd if=$IMAGE_DIR$IMAGE_NAME of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync

# gzip -cd $IMAGE_DIR$IMAGE_NAME | sudo dd of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync
# sudo dd if= of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync
# sudo $WRITE_CMD


 
### sudo dd if=$IMAGE_DIR$IMAGE_NAME of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync
### rm $IMAGE_DIR$IMAGE_NAME

# gzip -cd $IMAGE_NAME | sudo dd of=${WRITE_TARGET} bs=4M status=progress conv=fdatasync

else
  echo "Image NOT FOUND: $IMAGE_DIR$IMAGE_NAME!"
fi
