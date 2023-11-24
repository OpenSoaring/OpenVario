#!/bin/sh

# Transfer script for Up/Downloadng data to usbstick

USB_PATH="/usb/usbstick/openvario/"
OPENSOAR_PATH="/home/root/data/OpenSoarData"

case "$(basename "$0")" in
	'download-all.sh')
		SRC_PATH="$OPENSOAR_PATH"
		DEST_PATH="$USB_PATH/download/OpenSoarData"
		;;
	'upload-opensoar.sh')
		SRC_PATH="$USB_PATH/upload/OpenSoarData"
		DEST_PATH="$OPENSOAR_PATH"
		;;
	'upload-all.sh')
		SRC_PATH="$USB_PATH/upload"
		DEST_PATH="$OPENSOAR_PATH"
		;;
	*)
		>&2 echo 'call as download-all.sh, upload-opensoar.sh or upload-all.sh'
		exit 1
esac

if [ ! -d "$SRC_PATH" ] || [ ! -d "$DEST_PATH" ]; then
	>&2 echo "Source $SRC_PATH or destination path $DEST_PATH does not exist"
	exit 1
fi

if [ -z "$(find "$SRC_PATH" -type f | head -n 1 2>/dev/null)" ]; then
	echo 'No files found !!!'
else
    echo "Source:         '$SRC_PATH'"
    echo "Destination:    '$DEST_PATH'"
  # We use -c here due to cubieboards not having an rtc clock
	if rsync -rc --progress "${SRC_PATH}/" "$DEST_PATH/"; then
		echo 'All files transfered successfully.'
	else
		>&2 echo 'An error has occured!'
		exit 1
	fi
fi

# Sync the buffer to be sure data is on disk
sync
echo 'Done !!'
