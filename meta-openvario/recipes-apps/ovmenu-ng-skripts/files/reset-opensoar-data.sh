#!/bin/sh

# Reset the OpenSoarData from usbstick

USB_PATH="/usb/usbstick/openvario/"
OPENSOAR_PATH="/home/root/data/OpenSoarData"
CLUB_PATH="/home/root/.glider_club"
SRC_PATH="$USB_PATH/upload/OpenSoarData"
DEST_PATH="$OPENSOAR_PATH"

if [ ! -d "$SRC_PATH" ] || [ ! -d "$DEST_PATH" ]; then
	>&2 echo "Source $SRC_PATH or destination path $DEST_PATH does not exist"
	exit 1
fi

if [ -z "$(find "$SRC_PATH" -type f | head -n 1 2>/dev/null)" ]; then
	echo 'No files found !!!'
else
	echo 'Delete data at "$DEST_PATH/"!'
	rm -f $DEST_PATH/*
	mkdir -p $DEST_PATH/*
	echo 'Start copy "$DEST_PATH/"!'
	if rsync -r -c --progress "${SRC_PATH}/" "$DEST_PATH/"; then
		echo 'All data files transfered successfully.'
	else
		>&2 echo 'An error has occured!'
		exit 1
	fi

	if [ -d "$USB_PATH/upload/glider_club" ]; then
		echo 'Delete data at "$CLUB_PATH/"!'
		rm -f $CLUB_PATH/*
		echo 'Start copy "$CLUB_PATH/"!'
		if rsync -r -c --progress "$USB_PATH/upload/glider_club/" "$CLUB_PATH/"; then
			echo 'All club files transfered successfully.'
		else
			>&2 echo 'An error has occured!'
			exit 1
		fi
	fi
fi

# Sync the buffer to be sure data is on disk
sync
echo 'Done !!'
