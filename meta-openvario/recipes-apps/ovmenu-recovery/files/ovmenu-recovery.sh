#!/bin/bash

DEBUG_STOP="n"
DIALOGRC=/opt/bin/openvario.rc

# Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIRNAME=/mnt/openvario
#SDMOUNT=/mnt/sd
SDMOUNT=/sd

DEBUG_LOG=$DIRNAME/debug.log

# Target device (typically /dev/mmcblk0):
TARGET=/dev/mmcblk0

# Image file search string:
# images=$DIRNAME/images/OpenVario-linux*.gz
# old: images=$DIRNAME/images/OpenVario-linux*.gz
images=$DIRNAME/images/O*V*-*.gz
SDC_DIR=$DIRNAME/recover_data

function error_stop(){
    echo "Error-Stop: $1"
    read -p "Press enter to continue"
}

function debug_stop(){
    if [ "$DEBUG_STOP" = "y" ]; then
      echo "Debug-Stop: $1"
      read -p "Press enter to continue"
    fi
}

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
  dd if=/dev/mmcblk0 bs=1M count=50 | gzip > /$DIRNAME/backup/$datestring.img.gz | dialog --gauge "Backup Image ... " 10 50 0
#  (pv -n ${IMAGEFILE} | gunzip -c | dd bs=1024 skip=1024 | dd of=$TARGET bs=1024 seek=1024) 2>&1 | dialog --gauge "Writing Image ... " 10 50 0
 echo "Backup finished"
}


function select_image_old(){
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
		UpdateAll) 
        updateall
        recover_system
        ;;
	esac
	
}

function select_image(){
    #images=data/images/O*V*-*.gz

    let count=0 # define counting variable
    files=()        # define file array 
    files_nice=()   # define array with index + file description for dialogdialog
#------------------------------------------------------------------------------
    while read -r line; do # process file by file
        let count=$count+1
        files+=($count "$line")
        filename=$(basename "$line") 
        temp1=$(echo $filename | grep -oE '[0-9]{5}')
        if [ -n "$temp1" ]; then
            teststr=$(echo $filename | awk -F'-ipk-|.rootfs' '{print $2}')
            # teststr is now: 17119-openvario-57-lvds[-testing]
            temp2=$(echo $teststr | awk -F'-openvario-|-testing' '{print $2}')
        else
            # the complete (new) filename without extension
            # temp1=$(echo $filename | awk -F'/|.img' '{print $4}')
            temp1=${filename}
        fi
        # grep the buzzword 'testing'
        temp3=$(echo $filename | grep -o "testing")
        
        if [ -n "$temp2" ]; then
            temp="$temp1 hw=$temp2"
        else
            temp="$temp1"
        fi
        if [ -n "$temp3" ]; then
            temp="$temp ($temp3)"
        fi
        files_nice+=($count "$temp") # selection index + name
    done < <( ls -1 $images )
#------------------------------------------------------------------------------
##    images=$OV_DIRNAME/images/O*V*-*.gz
##    while read -r line; do # process file by file
##        let count=$count+1
##        files+=($count "$line")
##        filename=$(basename "$line") 
##        temp1=$(echo $filename | grep -oE '[0-9]{5}')
##        if [ -n "$temp1" ]; then
##            teststr=$(echo $filename | awk -F'-ipk-|.rootfs' '{print $2}')
##            # teststr is now: 17119-openvario-57-lvds[-testing]
##            temp2=$(echo $teststr | awk -F'-openvario-|-testing' '{print $2}')
##        else
##            # the complete (new) filename without extension
##            # temp1=$(echo $filename | awk -F'/|.img' '{print $4}')
##            temp1=${filename}
##        fi
##        # grep the buzzword 'testing'
##        temp3=$(echo $filename | grep -o "testing")
##        
##        if [ -n "$temp2" ]; then
##            temp="$temp1 hw=$temp2"
##        else
##            temp="$temp1"
##        fi
##        if [ -n "$temp3" ]; then
##            temp="$temp ($temp3)"
##        fi
##        files_nice+=($count "$temp (USB)") # selection index + name
##    done < <( ls -1 $images )
#------------------------------------------------------------------------------
    if [ -n "$files" ]; then
        dialog --backtitle "Selection upgrade image from file list" \
        --title "Select image" \
        --menu "Use [UP/DOWN] keys to move, ENTER to select" \
        18 60 12 "${files_nice[@]}" 2> "${SELECTION}"
        
        read SELECTED < ${SELECTION}
        let INDEX=$SELECTED+$SELECTED-1  # correct pointer in the arrays

        # IMAGEFILE=$(readlink -f $(ls -1 $images |sed -n "$(<${SELECTION}) p"))
        IMAGEFILE="${files[$INDEX]}"
        echo "-------------------------"
        echo "SELECTED  = ${files_nice[$INDEX]}"
        echo "IMAGEFILE = $IMAGEFILE"
        
    else
        echo "no image file available"
        IMAGEFILE=""
    fi
    # clear_display
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
    sync
    echo "Upgrade with '${IMAGEFILE}'"  >> $DEBUG_LOG
    IMAGE_NAME="$(basename $IMAGEFILE .gz)"
    (pv -n ${IMAGEFILE} | gunzip -c | dd of=$TARGET bs=16M) 2>&1 | \
    dialog --gauge "Writing Image ...\nfile = ${IMAGE_NAME}  " 10 50 0
    #########################################
    # remove the recovery file:
    echo "Upgrade '${IMAGEFILE}' finished"  >> $DEBUG_LOG
    rm -f $DIRNAME/ov-recovery.itb
}

function recover_system(){
    # recover OpenSoarData:
    if [ -d "$SDC_DIR" ]; then
        mkdir -p $SDMOUNT
        if [ -e "$SDC_DIR/part1/config.uEnv" ]; then
            mount ${TARGET}p1  $SDMOUNT
            source $SDC_DIR/part1/config.uEnv
            echo "sdcard/part1/config.uEnv"      >> $DEBUG_LOG
            echo "------------------------"      >> $DEBUG_LOG
            echo "rotation      = $rotation"     >> $DEBUG_LOG
            echo "brightness    = $brightness"   >> $DEBUG_LOG
            echo "font          = $font"         >> $DEBUG_LOG
            echo "fdt           = $fdtfile"      >> $DEBUG_LOG
            echo "========================"      >> $DEBUG_LOG
            if [ -n rotation ]; then
                echo "Set rotaton '$rotation'"  >> $DEBUG_LOG
                sed -i 's/^rotation=.*/rotation='$rotation'/' $SDMOUNT/config.uEnv
            fi
            if [ -n $font ]; then
                sed -i 's/^font=.*/font='$font'/' $SDMOUNT/config.uEnv
                echo "Set font '$font'"  >> $DEBUG_LOG
            fi
            if [ -n $brightness ]; then
              count=$(grep -c "brightness" $SDMOUNT/config.uEnv)
              if [ "$count" = "0" ]; then 
                echo "brightness=$brightness" >> $SDMOUNT/config.uEnv
                echo "Set brightness (1) '$brightness' NEW"  >> $DEBUG_LOG
              else
                sed -i 's/^brightness=.*/brightness='$brightness'/' $SDMOUNT/config.uEnv
                echo "Set brightness (2) '$brightness' UPDATE"  >> $DEBUG_LOG
              fi
            fi

            source $SDC_DIR/upgrade.cfg
            echo "sdcard/upgrade.cfg"           >> $DEBUG_LOG
            echo "------------------"           >> $DEBUG_LOG
            echo "ROTATION      = $ROTATION"    >> $DEBUG_LOG
            echo "BRIGHTNESS    = $BRIGHTNESS"  >> $DEBUG_LOG
            echo "FONT          = $FONT"        >> $DEBUG_LOG
            echo "SSH           = $SSH"         >> $DEBUG_LOG
            echo "========================"     >> $DEBUG_LOG
            if [ -n $ROTATION ]; then
                sed -i 's/^rotation=.*/rotation='$ROTATION'/' $SDMOUNT/config.uEnv
            fi
            if [ -n font ]; then
                sed -i 's/^font=.*/font='$font'/' $SDMOUNT/config.uEnv
            fi
            # TODO(August2111): check, if this correct
            if [ -n $BRIGHTNESS ]; then
                  count=$(grep -c "brightness" $SDMOUNT/config.uEnv)
                  if [ "$count" = "0" ]; then 
                    echo "brightness=$BRIGHTNESS" >> $SDMOUNT/config.uEnv
                    echo "Set BRIGHTNESS (3) '$BRIGHTNESS' NEW"  >> $DEBUG_LOG
                  else
                    sed -i 's/^brightness=.*/brightness='$BRIGHTNESS'/' $SDMOUNT/config.uEnv
                    echo "Set BRIGHTNESS (4) '$BRIGHTNESS' UPDATE"  >> $DEBUG_LOG
                  fi
            fi
            
            
            umount $SDMOUNT
        fi
        

        mount ${TARGET}p2  $SDMOUNT
        # removing '$SDMOUNT/home/root/ov-recovery.itb' not necessary because after
        # overwriting image this file/link isn't available anymore 
        # 1 - from new fw to new fw
        # 2 - from old fw to new fw
        # 3 - from new fw to old fw
        # 4 - from old fw to old fw
        case "$UPDATE_TYPE" in
        1) # from new to new do nothing, because data still available on partition 3 
        ;;
        2) # from old to new
           # partition 3  is new created and should be filled from USB stick in ovmenu shell
        ;;
        3) # from new to old 
          rm -rf $SDMOUNT/home/root/.xcsoar/*
          cp -frv $SDC_DIR/part2/XCSoarData/* $SDMOUNT/home/root/.xcsoar/
          if [ -d "$SDC_DIR/part2/glider_club" ]; then
            mkdir -p $SDMOUNT/home/root/.glider_club
            cp -frv $SDC_DIR/part2/glider_club/* $SDMOUNT/home/root/.glider_club/
          fi
        ;;
        4) # from old to old
          rm -rf $SDMOUNT/home/root/.xcsoar/*
          cp -frv $SDC_DIR/part2/xcsoar/* $SDMOUNT/home/root/.xcsoar/
          if [ -d "$SDC_DIR/part2/glider_club" ]; then
            mkdir -p $SDMOUNT/home/root/.glider_club
            cp -frv $SDC_DIR/part2/glider_club/* $SDMOUNT/home/root/.glider_club/
          fi
        ;;
        esac
        
        # restore the bash history:
        cp -fv  $SDC_DIR/part2/.bash_history $SDMOUNT/home/root/

        if [ -e "$SDC_DIR/connman.tar.gz" ]; then
          tar -zxf $SDC_DIR/connman.tar.gz --directory $SDMOUNT/
        fi
        
        if [ -e "$SDC_DIR/upgrade.cfg" ]; then
          cp $SDC_DIR/upgrade.cfg $SDMOUNT/home/root/upgrade.cfg
        fi
        
        ls -l $SDMOUNT/home/root/.xcsoar
        echo "ready OV upgrade!"
        echo "ready OV upgrade!"  >> $DEBUG_LOG
    else
        echo "' $SDC_DIR/part2/xcsoar' doesn't exist!"
        echo "' $SDC_DIR/part2/xcsoar' doesn't exist!"  >> $DEBUG_LOG
    fi


    echo "UPGRADE_LEVEL = '$UPGRADE_LEVEL'"  >> $DEBUG_LOG
    if [ -z $UPGRADE_LEVEL ]; then 
       echo "UPGRADE_LEVEL is set to '0000'"  >> $DEBUG_LOG
       UPGRADE_LEVEL=0;
    fi
    
    case "$UPGRADE_LEVEL" in
    0|1) echo "create 3rd partition 'ov-data'"
         echo "------------------------------"
         # debug: read -p "Press enter to continue"
         source $SDMOUNT/usr/bin/create_datapart.sh
         ;;
    *)   echo "unknown UPGRADE_LEVEL '$UPGRADE_LEVEL'"  >> $DEBUG_LOG ;;
    esac
    
    
    echo "Upgrade ready"  >> $DEBUG_LOG
    # set dmesg kernel level back to the highest:
    dmesg -n 8
    dmesg > $DIRNAME/dmesg.txt
    gunzip -f $DIRNAME/dmesg.txt
    umount $SDMOUNT
    sync
    #############################################################
    # only for debug-test
    # debug: read -p "Press enter to continue"
    # /bin/bash
    #############################################################
    
    # reboot:
    /opt/bin/reboot.sh
}

function update_system() {
	echo "Updating System ..." > /tmp/tail.$$
	/usr/bin/update-system.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}
#==============================================================================
#==============================================================================
#==============================================================================
#                Update - Begin
echo "Upgrade Start"
####################################################################

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

# debug_stop "... and begin..."
# ??? setfont cp866-8x14.psf.gz
if [ -b "${TARGET}p3" ]; then
  PARTITION3=/sd3
  mkdir -p $PARTITION3
  mount ${TARGET}p3  $PARTITION3
  DEBUG_LOG=$PARTITION3/debug.log
  # debug_stop "$PARTITION3 is mounted"
  sync
  ls $PARTITION3/
else 
  debug_stop "No $PARTITION3!!"
fi

# DEBUG_LOG=$DIRNAME/debug.log
echo "Upgrade start"  > $DEBUG_LOG
date  >> $DEBUG_LOG
time  >> $DEBUG_LOG
date; time  >> $DEBUG_LOG


if [ -e $PARTITION3/recover_data/upgrade.cfg ]; then
  SDC_DIR=$PARTITION3/recover_data
  source $SDC_DIR/upgrade.cfg
elif [ -e $SDC_DIR/upgrade.cfg ]; then
  source $SDC_DIR/upgrade.cfg
else
  IMAGEFILE="Not available!"
fi

echo "AugTest: Upgrade-Config: $SDC_DIR/upgrade.cfg "
debug_stop "Upgrade-Image: $IMAGEFILE "

# image file name with path!
if [ -e $PARTITION3/images/$IMAGEFILE ]; then
  # move it from sd card to ramdisk!
  # NO LINK: later mmcblk0 is overwritten
  cp "$PARTITION3/images/$IMAGEFILE" ./
  IMAGEFILE="./$IMAGEFILE"
  sync
elif [ -e $DIRNAME/images/$IMAGEFILE ]; then
  IMAGEFILE="$DIRNAME/images/$IMAGEFILE"
else
  IMAGEFILE="Not available!"
fi

echo "Detected image file: '$IMAGEFILE'!"  >> $DEBUG_LOG
debug_stop "Detected image file: '$IMAGEFILE'!"

# set dmesg minimum kernel level:
dmesg -n 1

if [ -e "$IMAGEFILE" ]; then
	echo "Update $IMAGEFILE !!!!"
	updateall
    recover_system
else
	main_menu
fi

#=====================================================================================
#=====================================================================================
#=====================================================================================
