#!/bin/bash

DIALOGRC=/opt/bin/openvario.rc

#Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIRNAME=/mnt/openvario

#Target device (typically /dev/mmcblk0)
TARGET=/dev/mmcblk0

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
	
	images=$DIRNAME/images/O*V*-*.gz

	let i=0 # define counting variable
	files=() # define working array
	files_nice=()
	while read -r line; do # process file by file
		let i=$i+1
		files+=($i "$line")
        filename=$(basename "$line") 
        # OpenVario-linux
		temp1=$(echo $line | grep -oE '[0-9]{5}')
		if [ -n "$temp1"]
		then
			# the complete (new) filename without extension
			# temp1=$(echo $line | awk -F'/|.img' '{print $4}')
			temp1=${filename}
		else
			temp2=$(echo $line | awk -F'openvario-|.rootfs' '{print $3}')
			temp3=$(echo $line | grep -o "testing")
		fi
		
		# temp="$temp1 $temp2 $temp3"
		files_nice+=($i "$temp1 $temp2 $temp3")
	done < <( ls -1 $images )
	
	if [ -n "$files" ]
	then
		# Search for images
		FILE=$(dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--menu "Use [UP/DOWN] keys to move, ENTER to select" \
		18 60 12 \
		"${files_nice[@]}" 3>&2 2>&1 1>&3) 
	else
		dialog --backtitle "${TITLE}" \
		--title "Select image" \
		--msgbox "\n\n No image file found !!" 10 40
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
 
	# make decision:
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

	(pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=16M) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
    #########################################
    # rename the recovery file:
    mv $DIRNAME/ov-recovery.itb $DIRNAME/ov-recovery.itx 
    # reboot:
    /opt/bin/reboot.sh
}


function update_system() {
	echo "Updating System ..." > /tmp/tail.$$
	/usr/bin/update-system.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# ??? setfont cp866-8x14.psf.gz

main_menu
