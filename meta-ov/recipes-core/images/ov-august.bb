require openvario-base-image.bb

# now wie use 3.5 GB for the partition - up to the moment with a 3rd data partition!
IMAGE_ROOTFS_SIZE ?= "3768320"
# IMAGE_ROOTFS_SIZE ?= "1048576"

IMAGE_INSTALL += "\
    xcsoar-august \
    xcsoar-menu \
    xcsoar-profiles \
    xcsoar-maps-default \
    sensord-testing \
    variod-testing \
    ovmenu-ng \
"

export IMAGE_BASENAME = "ov-august"

