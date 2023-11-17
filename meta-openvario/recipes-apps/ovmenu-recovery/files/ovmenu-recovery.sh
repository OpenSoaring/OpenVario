#!/bin/bash

DEBUG_STOP="n"
VERBOSE=n
DIALOGRC=/opt/bin/openvario.rc

# Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIRNAME=/mnt/openvario
SDMOUNT=/sd
PARTITION3=""

DEBUG_LOG=$DIRNAME/debug.log

# Target device (typically /dev/mmcblk0):
TARGET=/dev/mmcblk0

# Image file search string:
# images=$DIRNAME/images/OpenVario-linux*.gz
# old: images=$DIRNAME/images/OpenVario-linux*.gz
images=$DIRNAME/images/O*V*-*.gz
RECOVER_DIR=/home/root/recover_data

#------------------------------------------------------------------------------
function printv(){
    if [ "$VERBOSE" = "y" ]; then
      echo "$1"
    fi
}

#------------------------------------------------------------------------------
function error_stop(){
    echo "Error-Stop: $1"
    read -p "Press enter to continue"
}

#------------------------------------------------------------------------------
function debug_stop(){
    if [ "$DEBUG_STOP" = "y" ]; then
      echo "Debug-Stop: $1"
      read -p "Press enter to continue"
    fi
}

#------------------------------------------------------------------------------
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
  "UpdateAll"   "Update complete SD Card" \
  "UpdateuBoot"   "Update Bootloader only" \
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
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
function recover_system(){
    # recover OpenSoarData:
    if [ -d "$RECOVER_DIR" ]; then
        mkdir -p $SDMOUNT
        if [ -e "$RECOVER_DIR/part1/config.uEnv" ]; then
            mount ${TARGET}p1  $SDMOUNT
            source $RECOVER_DIR/part1/config.uEnv
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

            source $RECOVER_DIR/upgrade.cfg
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
          # 1 - from new fw to new fw
          # 2 - from old fw to new fw
          # 3 - from new fw to old fw
          # 4 - from old fw to old fw
        if [ "$UPGRADE_TYPE" = "1" ]; then  # new to new
          echo "nothing to restore"
        # elif [ "$UPGRADE_TYPE" = "2" ]; then  # old to new
          # do now the same as with the old target yet
          # later: copy the zip file only (if exist)...           
        else 
            rm -rf $SDMOUNT/home/root/.xcsoar/*  # delete the image data
            cp -frv $RECOVER_DIR/part2/xcsoar/* $SDMOUNT/home/root/.xcsoar/
        fi

        if [ -d "$RECOVER_DIR/part2/glider_club" ]; then
            mkdir -p $SDMOUNT/home/root/.glider_club
            cp -frv $RECOVER_DIR/part2/glider_club/* $SDMOUNT/home/root/.glider_club/
        fi
        # restore the bash history:
        cp -fv  $RECOVER_DIR/part2/.bash_history $SDMOUNT/home/root/
        
        if [ -e "$RECOVER_DIR/connman.tar.gz" ]; then
          tar -zxf $RECOVER_DIR/connman.tar.gz --directory $SDMOUNT/
        fi
        
        if [ -e "$RECOVER_DIR/upgrade.cfg" ]; then
          cp $RECOVER_DIR/upgrade.cfg $SDMOUNT/home/root/upgrade.cfg
        fi
        
        ls -l $SDMOUNT/home/root/.xcsoar
        echo "ready OV upgrade!"
        echo "ready OV upgrade!"  >> $DEBUG_LOG
    else
        echo "' $RECOVER_DIR/part2/xcsoar' doesn't exist!"
        echo "' $RECOVER_DIR/part2/xcsoar' doesn't exist!"  >> $DEBUG_LOG
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

#------------------------------------------------------------------------------
function update_system() {
  echo "Updating System ..." > /tmp/tail.$$
  /usr/bin/update-system.sh >> /tmp/tail.$$ &
  dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

#------------------------------------------------------------------------------
function save_old_system() {
    # 2nd: save boot folder to Backup from partition 1
    echo "2nd: save boot folder to Backup from partition 1"
    # -d is invalid option? rm -fr $RECOVER_DIR/part1

    echo "  copy command ..."
    mkdir -p $SDMOUNT
    mkdir -p $RECOVER_DIR/part1
    mount ${TARGET}p1  $SDMOUNT
    # cp is available on all (old) firmware
    # copy only files from interest (no picture, no uImage) 
    cp -fv  $SDMOUNT/config.uEnv        $RECOVER_DIR/part1/
    cp -fv  $SDMOUNT/image-version-info $RECOVER_DIR/part1/
    # 17119 don't have a *.dtb file...
    # cp -fv  $SDMOUNT/*.dtb              $RECOVER_DIR/part1/
    umount $SDMOUNT

    # 3rd: save OpenSoarData/XCSoarData from partition 2 (or 3):
    echo "3rd: save OpenSoarData / XCSoarData from partition 2 or 3"
    mount ${TARGET}p2  $SDMOUNT
    PART2_ROOT=$SDMOUNT/home/root
    # if [ "$FW_TYPE_BASE" = "2" ]; then # Base is new, data on 3rd partition 
    mkdir -p $RECOVER_DIR/part2/xcsoar
    if [ "$UPGRADE_TYPE" = "3" ]; then # Base is new, Target is old
      if [ -d "$PARTITION3/OpenSoarData" ]; then
          cp -rfv  $PARTITION3/OpenSoarData/* $RECOVER_DIR/part2/xcsoar/
          # alternative: cp -rfv  $PARTITION3/XCSoarData/* $RECOVER_DIR/part2/xcsoar/
      else
        error_stop "Wrong system: Partition 3 not available!"
      fi
    elif [ "$FW_TYPE_BASE" = "1" ]; then  # Base is old, data coming from '.xcsoar' folder
          cp -rfv  $PART2_ROOT/.xcsoar/* $RECOVER_DIR/part2/xcsoar/
    else
        debug_stop "Nothing to do for new firmwares!"
    fi
    cp -fv   $PART2_ROOT/.bash_history $RECOVER_DIR/part2/

    # HardLink at FAT isn't possible
    if [ -d "$PART2_ROOT/.glider_club" ]; then
        echo "save gliderclub data from partition 2"
        mkdir -p $RECOVER_DIR/part2/glider_club
        cp -frv $PART2_ROOT/.glider_club/* $RECOVER_DIR/part2/glider_club/
    fi
    
    debug_stop "saving finished"
    # Synchronize the commands (?)
    sync
    umount $SDMOUNT
}
#==============================================================================
#==============================================================================
#==============================================================================
#                Update - Begin
echo "Upgrade Start"
####################################################################

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

# delete ov-recovery.itb independent from success!
# debug_stop "... and begin..."
# ??? setfont cp866-8x14.psf.gz

mkdir -p $SDMOUNT
mount ${TARGET}p2  $SDMOUNT
rm -f $SDMOUNT/home/root/ov-recovery.itb
if [ -f "$SDMOUNT/home/root/upgrade.cfg" ]; then
  cp -fv "$SDMOUNT/home/root/upgrade.cfg" "/home/root/upgrade.cfg"
fi 

if [ -b "${TARGET}p3" ]; then
  PARTITION3=/mmc3
  mkdir -p $PARTITION3
  mount ${TARGET}p3  $PARTITION3
  DEBUG_LOG=$PARTITION3/debug.log
  debug_stop "$PARTITION3 is mounted"
  sync
  ls $PARTITION3/
else 
  PARTITION3=""  # empty
  debug_stop "No $PARTITION3!!"
fi

# DEBUG_LOG=$DIRNAME/debug.log
echo "Upgrade start"  > $DEBUG_LOG
date  >> $DEBUG_LOG
time  >> $DEBUG_LOG
date; time  >> $DEBUG_LOG


if [ -d $SDMOUNT/home/root/recover_data ]; then
  cp -rfv $SDMOUNT/home/root/recover_data /home/root 
  debug_stop "'copy recover_data' done!"
fi
umount $SDMOUNT

if [ -e $RECOVER_DIR/upgrade.cfg ]; then
  source $RECOVER_DIR/upgrade.cfg
elif [ -e $PARTITION3/recover_data/upgrade.cfg ]; then
  source $PARTITION3/upgrade.cfg
else
  error_stop "'upgrade.cfg' is not available!"
  IMAGEFILE="Not available!"
fi

echo "AugTest: Upgrade-Config: $RECOVER_DIR/upgrade.cfg "
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
  save_old_system
  if [ -n "$PARTITION3" ]; then
    umount $PARTITION3
  fi 
  updateall
  recover_system
else
  main_menu
fi

#=====================================================================================
#=====================================================================================
#=====================================================================================
