SUMMARY = "Automatically mount connected USB drives"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
PR = "r4"

inherit allarch systemd

SRC_URI = "\
	file://dev-usbstick.device \
	file://boot.mount \
	file://boot.automount \
	file://usb-usbstick.mount \
	file://usb-usbstick.automount \
	file://mount.ntfs \
	file://61-usbstick.rules \
"

SYSTEMD_SERVICE:${PN} = " \
	boot.mount \
	boot.automount \
	usb-usbstick.mount \
	usb-usbstick.automount \
"

do_configure() {
    :
}

do_compile() {
    :
}

do_install() {
	install -d ${D}${systemd_unitdir}/system
	install -m 0644 \
		${WORKDIR}/dev-usbstick.device \
		${WORKDIR}/boot.mount \
		${WORKDIR}/boot.automount \
		${WORKDIR}/usb-usbstick.mount \
		${WORKDIR}/usb-usbstick.automount \
		${D}${systemd_unitdir}/system

	# lets mount use the ntfs3 driver for sticks detected as "ntfs"
	install -d ${D}${base_sbindir}
	install -m 0755 ${WORKDIR}/mount.ntfs ${D}${base_sbindir}/mount.ntfs

	# points /dev/usbstick to the stick, partitioned or not
	install -d ${D}${sysconfdir}/udev/rules.d
	install -m 0644 ${WORKDIR}/61-usbstick.rules ${D}${sysconfdir}/udev/rules.d
}

FILES:${PN} += " \
	${systemd_unitdir}/system/dev-usbstick.device \
	${base_sbindir}/mount.ntfs \
	${sysconfdir}/udev/rules.d/61-usbstick.rules \
"
