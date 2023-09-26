#!/bin/bash

DIALOGRC=/opt/bin/openvario.rc

# Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIRNAME=/mnt/openvario

# Target device (typically /dev/mmcblk0)
TARGET=/dev/mmcblk0

# Image file search string:
images=$DIRNAME/images/OpenVario-linux*.gz

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

main_menu () {
while true
do
	### display main menu ###
	dialog --clear --nocancel --backtitle "OpenVario Recovery Tool" \
	--title "[ M A I N - M E N U ]" \
	--menu "You can use the UP/DOWN arrow keys" 15 50 6 \
	Flash_SDCard   "Write image to SD Card" \
	Backup-Image   "Backup complete Image" \
	Reboot   "Reboot" \
	Exit "Exit to shell" \
	ShutDown "ShutDown... " \
    2>"${INPUT}"
	 
	menuitem=$(<"${INPUT}")
 
	# make decsion 
case $menuitem in
	Flash_SDCard) select_image;;
	Backup-Image) backup_image;;
	Reboot) /opt/bin/reboot.sh;;
	Exit) /bin/bash;;
	ShutDown) shutdown -h now;;
esac

done
}

	
function backup_image(){
  datestring=$(date +%F)
  mkdir -p /$DIRNAME/backup
  # backup 1GB
  # dd if=/dev/mmcblk0 bs=1M count=1024 | gzip > /$DIRNAME/backup/$datestring.img.gz
  
  # test backup 50MB (Boot areal + 10 MB)
  dd if=/dev/mmcblk0 bs=1M count=50 | gzip > /$DIRNAME/backup/$datestring.img.gz | dialog --gauge "Writing Image ... " 10 50 0
  
  echo "Backup finished"
}


function select_image(){
	let i=0 # define counting variable
	declare -a files=() # define working array
	declare -a files_nice=()
	for line in $images; do
		let i=$i+1
		files+=($i "$line")
		filename=$(basename "$line") 
		files_nice+=($i "$filename")
	done

	if [ -n "$files" ]; then
		# Search for images
		FILE=$(dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--menu "Use [UP/DOWN] keys to move, ENTER to select" \
		18 60 12 \
		"${files_nice[@]}" 3>&2 2>&1 1>&3) 
	else
		dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--msgbox "\n\nNo image file found with \n'$images'!!" 10 40
		return
	fi
	IMAGEFILE=$(readlink -f $(ls -1 $images |sed -n "$FILE p"))
	
	# Show Image write options
	dialog --backtitle "${TITLE}" \
	--title "Select update method" \
	--menu "Use [UP/DOWN] keys to move, ENTER to select" \
	18 60 12 \
	"UpdateAll"	 "Update complete SD Card" \
	"UpdateuBoot"	 "Update Bootloader only" \
	2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")
 
	# make decsion 
	case $menuitem in
		UpdateuBoot) updateuboot;;
		UpdateAll) updateall;;
	esac
	
}

#update rootfs on mmcblk0
function updaterootfs(){
		
	(pv -n ${IMAGEFILE} | gunzip -c | dd bs=1024 skip=1024 | dd of=$TARGET bs=1024 seek=1024) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
		
}

function notimplemented(){

	dialog --backtitle "${TITLE}" \
			--msgbox "Not implemented yet !!" 10 60
}

#update uboot
function updateuboot(){
		
	#gunzip -c $(cat selected_image.$$) | dd of=$TARGET bs=1024 count=1024	
	(pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=1024 count=1024) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
		
}

#update updateall
function updateall(){

	(pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=16M) 2>&1 | dialog --gauge "Writing Image ...\nfile = ${IMAGEFILE}  " 10 50 0
    #########################################
    # rename the recovery file:
    mv $DIRNAME/ov-recovery.itb $DIRNAME/ov-recovery.itx
    # recover XCSoarData:
    if [ -d "${DIRNAME}/sdcard/part2/xcsoar" ]; then
        mkdir -p /mnt/sd
        mount ${TARGET}p2  /mnt/sd
        ls -l /mnt/sd/home/root/.xcsoar
        
        rm -rf /mnt/sd/home/root/.xcsoar/*
        cp -frv ${DIRNAME}/sdcard/part2/xcsoar/* /mnt/sd/home/root/.xcsoar/
        if [ -d "${DIRNAME}/sdcard/part2/glider_club" ]; then
          mkdir -p /mnt/sd/home/root/.glider_club
          cp -frv ${DIRNAME}/sdcard/part2/glider_club/* /mnt/sd/home/root/.glider_club/
        fi

        ls -l /mnt/sd/home/root/.xcsoar
        echo "ready OV upgrade!"
        # read -p "Press enter to continue"
    else
        echo "' ${DIRNAME}/sdcard/part2/xcsoar' doesn't exist!"
    fi

    # reboot:
    /opt/bin/reboot.sh
}


function update_system() {
	echo "Updating System ..." > /tmp/tail.$$
	/usr/bin/update-system.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# ??? setfont cp866-8x14.psf.gz

read IMAGEFILE < $DIRNAME/upgrade.file

echo "UpdateFile: $IMAGEFILE "

# image file name with path!
IMAGEFILE="$DIRNAME/images/$IMAGEFILE"
echo $IMAGEFILE > $DIRNAME/upgrade.fileX

if [ -e "$IMAGEFILE" ];
then
	echo "Update $IMAGEFILE !!!!"
	updateall
else
	main_menu
fi

#=====================================================================================
#=====================================================================================
#=====================================================================================
