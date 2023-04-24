SUMMARY = "Distribution of boot up and recovery itb's with kernel and boot up initramfs built in"
HOMEPAGE = "none"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PR = "r27"

S = "${WORKDIR}/${PN}-${PV}"

SRC_URI = "\
        file://openvario-recovery.its \
        file://sun7i-a20-cubieboard2.dtb \
        file://zImage.bin \
        "

DEPENDS = "\
        dtc-native \
        virtual/kernel \
        openvario-recovery-initramfs \
        u-boot-mkimage-native \
        u-boot \
	"

do_compile[deptask] = "do_rm_work"

do_configure () {
	cp ${WORKDIR}/openvario-recovery.its ${S}

	# cp -v ${DEPLOY_DIR_IMAGE}/uImage ${S}
	# cp -v ${WORKDIR}/zImage.bin ${S}/Image
	# dd if=${S}/uImage-${MACHINE}.bin of=${S}/zImage skip=64 iflag=skip_bytes
	# dd if=${S}/uImage-${MACHINE}.bin of=${S}/uImage skip=64 iflag=skip_bytes

	cp -v ${DEPLOY_DIR_IMAGE}/openvario-base-initramfs-${MACHINE}.cpio.gz ${S}/initramfs.cpio.gz
	
    cp -v ${WORKDIR}/sun7i-a20-cubieboard2.dtb ${S}/openvario.dtb
    # cp -v ${DEPLOY_DIR_IMAGE}/openvario.dtb ${S}
	# cp -v ${DEPLOY_DIR_IMAGE}/fex.bin ${S}/script.bin
	
	
}

do_compile () {
    # Extract kernel from uImage
    # dd if=uImage of=Image bs=64 skip=1
	cp -v ${WORKDIR}/zImage.bin ${S}/Image
    #dumpimage -i uImage -T kernel Image
}

do_mkimage () {
    # show mkimage version:
    echo "========================================="
    mkimage -V
    echo "========================================="
    # Build ITB with provided config
    mkimage -A arm -f ${S}/openvario-recovery.its ${S}/ov-recovery.itb
}

addtask mkimage after do_configure before do_install

do_install () {
	cp ${WORKDIR}/${PN}-${PV}/ov-recovery.itb ${DEPLOY_DIR_IMAGE}
}
