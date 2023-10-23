require openvario-base-image.bb

#IMAGE_ROOTFS_SIZE ?= "3768320"
# IMAGE_ROOTFS_SIZE ?= "1048576"
IMAGE_ROOTFS_SIZE ?= "524288"
# TEST_SIZE_XXL = "524288"
# IMAGE_ROOTFS_EXTRA_SPACE ?= $(expr ${TEST_SIZE_XXL} \+ ${TEST_SIZE_XXL})
# IMAGE_ROOTFS_EXTRA_SPACE = "524288"
IMAGE_OVERHEAD_FACTOR = "2.0"

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
