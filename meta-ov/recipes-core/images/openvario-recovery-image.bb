SUMMARY = "Distribution of boot up and recovery itb's with kernel and boot up initramfs built in"
HOMEPAGE = "none"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PR = "r28"

S = "${WORKDIR}/${PN}-${PV}"

SRC_URI = "\
        file://openvario-recovery.its \
        file://sun7i-a20-cubieboard2.dtb \
        file://zImage.bin \
        file://openvario-initramfs.cpio.gz \
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
	###	dd if=${DEPLOY_DIR_IMAGE}/uImage of=${S}/Image bs=64 skip=1
	###
    cp -v ${WORKDIR}/zImage.bin ${S}/Image
	# dd if=${S}/uImage-${MACHINE}.bin of=${S}/zImage skip=64 iflag=skip_bytes
	# dd if=${S}/uImage-${MACHINE}.bin of=${S}/uImage skip=64 iflag=skip_bytes

	# cp -v ${DEPLOY_DIR_IMAGE}/openvario-base-initramfs-${MACHINE}.cpio.gz ${S}/initramfs.cpio.gz
    cp -v ${WORKDIR}/openvario-initramfs.cpio.gz ${S}/initramfs.cpio.gz
	
	#
    cp -v ${WORKDIR}/sun7i-a20-cubieboard2.dtb ${S}/openvario.dtb
	###	cp -v ${DEPLOY_DIR_IMAGE}/${MACHINE}.dtb ${S}/openvario.dtb
	# cp -v ${DEPLOY_DIR_IMAGE}/openvario.dtb ${S}
	# cp -v ${DEPLOY_DIR_IMAGE}/fex.bin ${S}/script.bin
	
	
	#cp -rv /home/august2111/OpenVario/OpenVario/tmp/work/openvario_57_lvds-ovlinux-linux-gnueabi/openvario-image/1.0-r0/recipe-sysroot-native/ \
	# ${WORKDIR}/recipe-sysroot-native/
	# Attention:this is a wrong binary from the Linux system, not the builded
	# mkimage with version 2022.01
	# 
    cp -v /usr/bin/mkimage ${S}/mkimage_x
	# sudo chmod 757 ${S}/mkimage_x
}

do_compile () {
	# Extract kernel from uImage
	# dd if=uImage of=Image bs=64 skip=1
	# cp -v ${WORKDIR}/zImage.bin ${S}/Image
	echo "========================================="
	echo $(pwd)
	echo "========================================="
	# dumpimage -i uImage -T kernel Image
}

do_mkimage () {
    # show mkimage version:
    echo "========================================="
    # 
    ${WORKDIR}/recipe-sysroot-native/usr/bin/mkimage -V
    /home/august2111/OpenVario/OpenVario/tmp/work/openvario_57_lvds-ovlinux-linux-gnueabi/u-boot/1_2023.01-r1/recipe-sysroot-native/usr/bin/mkimage -V
    ${S}/mkimage_x -V
    mkimage -V
    uboot-mkimage -V
    echo "========================================="
    # Build ITB with provided config
    # /home/august2111/OpenVario/OpenVario/tmp/work/openvario_57_lvds-ovlinux-linux-gnueabi/u-boot/1_2022.07-r1/recipe-sysroot-native/usr/bin/mkimage -A arm -f ${S}/openvario-recovery.its ${S}/ov-recovery.itb
    ${S}/mkimage_x -A arm -f ${S}/openvario-recovery.its ${S}/ov-recovery.itb
    # mkimage -A arm -f ${S}/openvario-recovery.its ${S}/ov-recovery.itb
    # ${S}/mkimage_x -A arm -f ${S}/openvario-recovery.its ${S}/test.itb
    # $(pwd)
}

addtask mkimage after do_configure before do_install

do_install () {
	cp ${WORKDIR}/${PN}-${PV}/ov-recovery.itb ${DEPLOY_DIR_IMAGE}
	cp ${WORKDIR}/${PN}-${PV}/ov-recovery.itb ${DEPLOY_DIR_IMAGE}/test.itb
	# cp ${WORKDIR}/${PN}-${PV}/test.itb ${DEPLOY_DIR_IMAGE}
}
