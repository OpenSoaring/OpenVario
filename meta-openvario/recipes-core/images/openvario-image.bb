require openvario-base-image.bb

#IMAGE_ROOTFS_SIZE ?= "3768320"
# IMAGE_ROOTFS_SIZE ?= "1048576"
# IMAGE_ROOTFS_SIZE ?= "524288"
# IMAGE_ROOTFS_SIZE ?= "483328" ==> 0x20800000
IMAGE_ROOTFS_SIZE ?= "475136"

IMAGE_INSTALL += "\
    opensoar \
    xcsoar \
    xcsoar-menu \
    xcsoar-profiles \
    xcsoar-maps-default \
    caltool \
    sensord \
    variod \
    ovmenu-ng \
"

IMAGE_INSTALL += "e2fsprogs-mke2fs "

export IMAGE_BASENAME = "openvario-image"
