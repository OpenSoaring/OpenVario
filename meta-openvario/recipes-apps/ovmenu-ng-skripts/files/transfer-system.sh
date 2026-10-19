#!/bin/sh
#
# transfer-xcsoar.sh
# System backup transfer script to and from usbstick for Openvario and XCSoar
#
# Created by lordfolken         2022-02-08
# Enhanced by 7lima & Blaubart  2022-06-19
#
# This backup and restore script stores all XCSoar settings and relevant
# Openvario settings like:
#
# -brightness of the display
# -rotation
# -touch screen calibration
# -language settings
# -dropbear settings
# -SSH, variod and sensord status
# 
# backups are stored at USB stick at:
# openvario/backup/<MAC address of eth0>/
# So you can store backups from more than one OV on the same stick!
#
# Usage: transfer-system.sh backup|restore [--data FOLDER]... [MAIN_APP]
#
# The data partition (/home/root/data) holds maps, flights, caches and
# firmware images and easily grows beyond a gigabyte, which takes hours
# on a stick mounted with "sync".  A backup therefore copies only the
# settings, plus each folder directly below the data partition that is
# named with --data.  It always writes a list of all files on the data
# partition to data-files.txt in the backup directory, so that it is at
# least known what was there.  A restore copies back whatever the backup
# holds.

echo ' [==========] Starting'
echo ' [#=========] Wait until "DONE !!" appears before you exit!'

# Provident background system buffer sync to help later syncs finish quicker
sync&

TRANSFER_OPTION=$1
MAIN_APP=
shift

# Where the menu mounts the data partition
DATA_PATH=/home/root/data

# The folders below the data partition to back up as well, one rsync
# filter rule per line; a name with a slash or a dot entry could reach
# outside the data partition, so only plain existing folder names count.
DATA_RULES=
while [ $# -gt 0 ]
do
	case "$1" in
	--data)
		case "$2" in
		''|.|..|*/*)
			>&2 echo " Invalid data folder '$2' - nothing done."
			exit 1;;
		esac
		if [ ! -d "$DATA_PATH/$2" ]; then
			>&2 echo " There is no folder '$2' in $DATA_PATH - nothing done."
			exit 1
		fi
		DATA_RULES="$DATA_RULES+ /home/root/data/$2/
"
		shift 2;;
	*)
		# the older calls pass the name of the main program here,
		# which only appears in the messages
		MAIN_APP=$1
		shift;;
	esac
done

# File for the exit status of rsync, which runs at the start of a pipe
RSYNC_STATUS=/tmp/transfer-system.$$

# Runs rsync with the given arguments and shows its overall progress.
# rsync separates its progress updates with carriage returns, which awk
# takes as the record separator; awk flushes each line, because output
# into a pipe is otherwise held back until the end.
# Blind waiting made a long transfer look as if it hung, so this prints
# a short line whenever another 5 percent or another 5 MB are done, and
# at least every 30 progress updates of rsync (about half a minute while
# a large file is copied slowly), so that a slow copy still shows signs
# of life.  The lines stay short because the program dialog that shows
# them does not wrap them.  The exit status of rsync goes into a file,
# because a call at the end of a pipe runs in a subshell, which cannot
# set variables of the script; rsync_result reads it afterwards.
run_rsync() {
	{ rsync --info=progress2 --no-inc-recursive "$@"
	  echo $? > "$RSYNC_STATUS"; } |
	awk 'function size(b) {
		return b < 1048576 ? sprintf("%.0f kB", b / 1024) \
		                   : sprintf("%.1f MB", b / 1048576)
	}
	BEGIN { RS = "\r" }
	$2 ~ /%$/ {
		bytes = $1; gsub(/,/, "", bytes); bytes += 0
		pct = $2; sub(/%/, "", pct); pct += 0
		if (++updates >= 30 || pct >= last_pct + 5 ||
		    (pct == 100 && last_pct < 100) ||
		    bytes >= last_bytes + 5242880) {
			printf " %3d%%  %10s  %s\n", pct, size(bytes), $3
			fflush()
			last_pct = pct; last_bytes = bytes; updates = 0
		}
		total = bytes
	}
	END { printf " %s copied.\n", size(total) }'
}

# Sets RSYNC_EXIT to the exit status of the last run_rsync and succeeds
# if that was 0.
rsync_result() {
	RSYNC_EXIT=`cat "$RSYNC_STATUS" 2> /dev/null`
	rm -f "$RSYNC_STATUS"
	: ${RSYNC_EXIT:=1}
	test "$RSYNC_EXIT" -eq 0
}

# Path where the USB stick is mounted
USB_PATH=/usb/usbstick

# XCSoar settings path
export XCSOAR_PATH=/home/root/.xcsoar

# XCSoar upload path
XCSOAR_UPLOAD_PATH=openvario/upload/xcsoar

# Backup path within the USB stick
BACKUP=openvario/backup

# MAC address of the Ethernet device eth0 to do a separate backup
MAC=`ip li|grep -A 1 eth0|tail -n 1|cut -d ' ' -f 6|sed -e s/:/-/g`

#### aug 2024-01-03 # Restore Shell Function: calls rsync with unified options. 
#### aug 2024-01-03 # Copies all files and dirs from source recursively. Parameters:
#### aug 2024-01-03 # $1 source
#### aug 2024-01-03 # $2 target
#### aug 2024-01-03 # $3 comment about type of items
#### aug 2024-01-03 restore() {
#### aug 2024-01-03 	if 
#### aug 2024-01-03 		# We use --checksum here due to cubieboards not having an rtc clock
#### aug 2024-01-03 		rsync --recursive --mkpath --checksum --quiet --progress "$1" "$2"
#### aug 2024-01-03 		test ${RSYNC_EXIT:=$?} -eq 0
#### aug 2024-01-03 	then
#### aug 2024-01-03 		echo " [####======] All $3 files have been restored."
#### aug 2024-01-03 	else 
#### aug 2024-01-03 		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
#### aug 2024-01-03 	fi
#### aug 2024-01-03 	# Provident system buffer sync to help later syncs finish quicker
#### aug 2024-01-03 	sync&
#### aug 2024-01-03 }

# The stick is mounted by a systemd automount unit, which keeps an
# "autofs" entry on $USB_PATH even while no stick is plugged in.
# Without a real mount, rsync would fail or write the backup into the
# mount point directory on the root file system, so refuse right away.
ls "$USB_PATH" > /dev/null 2>&1    # lets systemd mount a stick
if ! awk -v p="$USB_PATH" '$2 == p && $3 != "autofs" { found = 1 }
                          END { exit !found }' /proc/mounts; then
	>&2 echo " No USB stick found at $USB_PATH - nothing done."
	exit 1
fi

case "$TRANSFER_OPTION" in
backup)
	echo ' [##========] System check ...'
	
	# Store SSH status 
	if   /bin/systemctl --quiet is-enabled dropbear.socket
	then	echo enabled
	elif /bin/systemctl --quiet is-active  dropbear.socket
	then	echo temporary
	else	echo disabled  
	fi > /home/root/ssh-status

	# Store variod and sensord status
	for DAEMON in variod sensord
	do
		if /bin/systemctl --quiet is-enabled $DAEMON
		then echo  enabled
		else echo disabled  
		fi > /home/root/$DAEMON-status
	done
	
	# Store if profiles are protected or not
	if [[ 'opkg list-installed | grep "e2fsprogs -"' == *"e2fsprogs"* ]]; 
	then
	PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
	for PROFILE; 
	do
		mkdir -p /home/root/profile-settings
		PROFILE_FILE=`basename "$PROFILE"`
		PROFILE_NAME=${PROFILE_FILE%.*}
		if lsattr "$PROFILE" | cut -b 5 | fgrep -q i; 
		then echo protected
		else echo unprotected
		fi > /home/root/profile-settings/$PROFILE_NAME 
	done
	' -- {} +
	fi

	# Copy brightness setting
	cat /sys/class/backlight/lcd/brightness > /home/root/brightness

	echo ' [###=======] Listing the files of the data partition ...'
	# A list of everything on the data partition costs a few seconds and
	# little space, and tells what was there even when the folders were
	# not backed up.
	mkdir -p "$USB_PATH/$BACKUP/$MAC"
	{
		echo "Files on the data partition $DATA_PATH, `date`"
		echo
		du -sh "$DATA_PATH"/* 2> /dev/null
		echo
		ls -lAR "$DATA_PATH"
	} > "$USB_PATH/$BACKUP/$MAC/data-files.txt" 2>&1

	echo ' [####======] Starting backup ...'
	# Copy all directories and files from the list below to the backup
	# directory recursively.  The touch screen files only exist after a
	# calibration, and rsync reports a missing entry as an error, so they
	# are listed only when present.
	# We use --checksum here due to cubieboards not having an rtc clock;
	# rsync then reads all files on both sides before it copies, which
	# shows no progress for a while when large folders are included.
	# The data partition below /home/root is left out except for the
	# folders named with --data (see the top of this script).
	OPTIONAL_FILES=
	for FILE in /etc/udev/rules.d/libinput-ts.rules /etc/pointercal
	do
		if [ -e "$FILE" ]; then OPTIONAL_FILES="$OPTIONAL_FILES $FILE"; fi
	done
	printf '%s' "$DATA_RULES" > "$RSYNC_STATUS.rules"
	if [ -n "$DATA_RULES" ]; then
		echo ' Comparing with the backup on the stick, this can take a while ...'
	fi
	printf '%s\n' /etc/dropbear /home/root /opt/conf /var/lib/connman \
		/boot/config.uEnv $OPTIONAL_FILES |
	run_rsync --files-from - --archive --recursive \
		--relative --mkpath --checksum --safe-links \
		--filter="merge $RSYNC_STATUS.rules" \
		--exclude='/home/root/data/*' \
		/ "$USB_PATH/$BACKUP/$MAC"/
	if rsync_result
	then
		echo ' [######====] All files and settings have been backed up.'
	else
		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
	fi
	rm -f "$RSYNC_STATUS.rules";;
	
restore)
	echo ' [##========] Starting restore ...'

	# Eliminate /etc/opkg backup in case it's present
	rm -rf "$USB_PATH/$BACKUP/$MAC"/etc/opkg/

	# We use --checksum here due to cubieboards not having an rtc clock.
	# The file list of the data partition is only for reading.
	run_rsync --recursive --mkpath --checksum \
		--exclude=/data-files.txt "$USB_PATH/$BACKUP/$MAC/" "/"
	if rsync_result
	then
		echo " [####======] All Openvario and $MAIN_APP files have been restored."
	else 
		>&2 echo " An rsync error $RSYNC_EXIT has occurred!"
	fi
	# Provident system buffer sync to help later syncs finish quicker
	sync&

	# restore "$USB_PATH/$BACKUP/$MAC"/ / "Openvario and XCSoar"
	/bin/systemctl restart  --quiet --now ts_uinput

	# Restore SSH status 
	case `cat /home/root/ssh-status` in
	enabled)
		/bin/systemctl enable  --quiet --now dropbear.socket
		echo " [####======] SSH has been enabled permanently.";;
	temporary)
		/bin/systemctl disable --quiet --now dropbear.socket
		/bin/systemctl start   --quiet --now dropbear.socket
		echo " [####======] SSH has been enabled temporarily.";;
	disabled)
		/bin/systemctl disable --quiet --now dropbear.socket
		echo " [####======] SSH has been disabled.";;
	esac
	
	# Restore variod and sensord status 
	for DAEMON in variod sensord
	do
		case `cat /home/root/$DAEMON-status` in
		enabled)  /bin/systemctl  enable --quiet --now $DAEMON
		          echo " [#####=====] $DAEMON has been enabled.";;
		disabled) /bin/systemctl disable --quiet --now $DAEMON
		          echo " [#####=====] $DAEMON has been disabled.";;
		esac
	done

	# Restore protection for profiles if necessary
	if [[ 'opkg list-installed | grep "e2fsprogs -"' == *"e2fsprogs"* ]]; 
	then
		PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
		for PROFILE; 
		do
			PROFILE_FILE=`basename "$PROFILE"`
			PROFILE_NAME=${PROFILE_FILE%.*}
			case `cat /home/root/profile-settings/"$PROFILE_NAME"` in
			protected)   chattr +i "$XCSOAR_PATH"/"$PROFILE_NAME.prf"
		 	             echo " [######====] $PROFILE_NAME.prf has been protected.";;
			unprotected) echo " [######====] $PROFILE_NAME.prf is still unprotected.";;
			esac
		done
		' -- {} +
	else 
		PROFILE= find "$XCSOAR_PATH" -maxdepth 1 -type f -name '*.prf' -exec sh -c '
		for PROFILE; 
		do
			PROFILE_FILE=`basename "$PROFILE"`
			PROFILE_NAME=${PROFILE_FILE%.*}
			case `cat /home/root/profile-settings/"$PROFILE_NAME"` in
			protected)  echo " You try to protect $PROFILE_NAME.prf, but chattr is not installed!";;
			esac
		done
		' -- {} +
	fi

	# Restore brightness setting
	cat /home/root/brightness > /sys/class/backlight/lcd/brightness
	echo " [#######===] brightness setting has been restored."
	
	# Restore rotation setting
	grep "rotation" /boot/config.uEnv | cut -d '=' -f 2 | tr -d '"' > /sys/class/graphics/fbcon/rotate
	echo " [########==] rotation setting has been restored.";;
*)
	>&2 echo "not valid calling parameter: $TRANSFER_OPTION"
	exit 1;;
esac

# Sync the system buffer to make sure all data is on disk
echo ' [#########=] Please wait a moment, synchronization is not yet complete!'
sync
echo ' [##########] DONE !! ---------------------------------------------------'
exit $RSYNC_EXIT
