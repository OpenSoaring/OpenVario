#!/bin/sh

# Transfer script for Up/Downloadng data to usbstick

USB_PATH="/usb/usbstick/openvario/"
OPENSOAR_PATH="/home/root/data/OpenSoarData"

RSYNC_OPTION=""
DATA_FOLDER="OpenSoarData"

case "$TRANSFER_OPTION" in
	'download-data')
        echo "Syncronizing $DATA_FOLDER with USB "
		SRC_PATH="$OPENSOAR_PATH"
		DEST_PATH="$USB_PATH/download/$DATA_FOLDER"
		;;
	'upload-data')
        echo "Copy USB data to $DATA_FOLDER"
		SRC_PATH="$USB_PATH/upload/$DATA_FOLDER"
		DEST_PATH="$OPENSOAR_PATH"
		;;
	'sync-data' )
        echo "Syncronizing USB data with $DATA_FOLDER"
		SRC_PATH="$USB_PATH/upload/$DATA_FOLDER"
		DEST_PATH="$OPENSOAR_PATH"
        RSYNC_OPTION="--delete"; fi
	'upload-all')
        echo "Syncronizing complete USB data folder 'upload' with data partition"
		SRC_PATH="$USB_PATH/upload"
		DEST_PATH="$OPENSOAR_PATH"
		;;
	*)
		>&2 echo 'transfer option unknown!'
		exit 1
esac

if [ ! -d "$SRC_PATH" ] || [ ! -d "$DEST_PATH" ]; then
	>&2 echo "Source $SRC_PATH or destination path $DEST_PATH does not exist"
	exit 1
fi

if [ -z "$(find "$SRC_PATH" -type f | head -n 1 2>/dev/null)" ]; then
	echo 'No files found !!!'
else
    echo "Transfer-Cmd:   '$TRANSFER_OPTION'"
    echo "Source:         '$SRC_PATH'"
    echo "Destination:    '$DEST_PATH'"
  # We use -c here due to cubieboards not having an rtc clock
	if rsync -rc --progress $RSYNC_OPTION "${SRC_PATH}/" "$DEST_PATH/"; then
		echo 'All files transfered successfully.'
	else
		>&2 echo 'An error has occured!'
		exit 1
	fi
fi

# Sync the buffer to be sure data is on disk
sync
RSYNC_OPTION=""
echo 'Done !!'
