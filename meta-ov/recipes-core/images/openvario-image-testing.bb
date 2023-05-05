require openvario-base-image.bb

# IMAGE_ROOTFS_SIZE ?= "3768320" = 0x39 8000 (+ 0x6 8000 = 0x40 0000)
# IMAGE_ROOTFS_SIZE ?= "1048576" = 0x10 0000
#  655.260 = 0x0A 0000 
# IMAGE_ROOTFS_SIZE ?= "655260"
# Doubled: 0x20 0000
# IMAGE_ROOTFS_SIZE ?= "2097152"
# : 0x18 0000
# IMAGE_ROOTFS_SIZE ?= "1572864"
# : 0x1C 0000
IMAGE_ROOTFS_SIZE ?= "1835008"

IMAGE_INSTALL += "\
    xcsoar \
    xcsoar-menu \
    xcsoar-profiles \
    xcsoar-maps-default \
    sensord-testing\
    variod-testing \
    ovmenu-ng \
"

export IMAGE_BASENAME = "openvario-image-testing"
