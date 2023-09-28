#!/bin/bash

echo "Firmware Upgrade OpenVario"
echo "=========================="

DEBUG_STOPS="n"

# USB_STICK=usb
USB_STICK=/usb/usbstick

DIALOG_CANCEL=1
SELECTION=/tmp/output.sh.$$

# the OV dirname at USB stick
OV_DIRNAME=$USB_STICK/openvario

# temporary directories at USB stick to save the setting informations
SDC_DIR=$OV_DIRNAME/sdcard
MNT_DIR="mnt"
# MNT_DIR=$OV_DIRNAME/usb

# SD card:
TARGET=/dev/mmcblk0
IMAGEFILE=""
HW_TARGET="0000"
HW_BASE="0000"
FILENAME_TYPE=0

BACKUP_DIR=$SDC_DIR
    # delete: MOUNT_DIR1=$MNT_DIR/part1
# partition 1 of SD card is mounted as '/boot'!
MOUNT_DIR1=/boot
    # delete: MOUNT_DIR2=$MNT_DIR/part2
# partition 2 of SD card is mounted on the root of the system
MOUNT_DIR2=/

function select_image(){
    images=$OV_DIRNAME/images/O*V*-*.gz

    let i=0 # define counting variable
    files=()        # define file array 
    files_nice=()   # define array with index + file description for dialog
    while read -r line; do # process file by file
        let i=$i+1
        files+=($i "$line")
        filename=$(basename "$line") 
        temp1=$(echo $filename | grep -oE '[0-9]{5}')
        if [ -n "$temp1" ]; then
            temp2=$(echo $filename | awk -F'openvario-|.rootfs' '{print $3}')
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
        files_nice+=($i "$temp") # selection index + name
    done < <( ls -1 $images )
    
    
    if [ -n "$files" ]; then
        # Search for images
        # FILE=$(
        dialog --backtitle "Selection upgrade image from file list" \
        --title "Select image" \
        --menu "Use [UP/DOWN] keys to move, ENTER to select" \
        18 60 12 "${files_nice[@]}" 2> "${SELECTION}"
        
        IMAGEFILE=$(readlink -f $(ls -1 $images |sed -n "$(<${SELECTION}) p"))
    else
        echo "no image file available"
        IMAGEFILE=""
    fi

    if [ ! -e "$IMAGEFILE" ]; then
        dialog --backtitle "${TITLE}" \
        --title "Select image" \
        --msgbox "\n\n No image file found !!" 10 40
        echo "no image file... 2nd"
        exit
    else
        IMAGE_NAME="$(basename $IMAGEFILE)"
        TESTING=$(echo $IMAGE_NAME | grep -o "testing")
        # grep the buzzword 'testing'
        FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]{5}')
        if [ -n "$FW_VERSION" ]; then
            FILENAME_TYPE=1
            # find the part between 'openvario- 
            TARGET=$(echo $IMAGE_NAME | awk -F'openvario-|.rootfs' '{print $3}')
            case $TARGET in
                57-lvds)      HW_TARGET="ch57";;
                7-CH070)      HW_TARGET="ch70";;
                7-PQ070)      HW_TARGET="pq70";;
                7-AM070-DS2)  HW_TARGET="ds70";;
                43-rgb)       HW_TARGET="am43";;
                *)            HW_TARGET="unknown";;
            esac
        else
            # grep a version in form '##.##.##-##' like '3.0.2-20' 
            FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
            FILENAME_TYPE=2
            TARGET=$(echo $filename | awk -F'CB2-|.img' '{print $3}')
            case $TARGET in
                CH57)        HW_TARGET="ch57";;
                CH70)        HW_TARGET="ch70";;
                PQ70)        HW_TARGET="pq70";;
                AM70_DS2)    HW_TARGET="ds70";;
                AM43)        HW_TARGET="am43";;
                *)           HW_TARGET="unknown";;
            esac
        fi
        echo "selected image file:    $IMAGE_NAME"
    fi
}


function save_system(){
    #================== System Config =======================================================
    echo "1st: save system config in config.uSys for restoring reason"
    # 1st save system config in config.uSys for restoring reason
    mkdir -p $BACKUP_DIR
    
    # start with a new 'config.uSys':
    rm -f $BACKUP_DIR/config.uSys
        # delete: echo "" > $BACKUP_DIR/config.uSys
    if /bin/systemctl --quiet is-enabled dropbear.socket; then
        echo "SSH=\"enabled\""
        echo "SSH=\"enabled\"" >> $BACKUP_DIR/config.uSys
    elif /bin/systemctl --quiet is-active dropbear.socket; then
        echo "SSH=\"temporary\""
        echo "SSH=\"temporary\"" >> $BACKUP_DIR/config.uSys
    else
        echo "SSH=\"disabled\""
        echo "SSH=\"disabled\"" >> $BACKUP_DIR/config.uSys
    fi

    echo "BRIGHTNESS=\"$(</sys/class/backlight/lcd/brightness)\""
    echo "BRIGHTNESS=\"$(</sys/class/backlight/lcd/brightness)\"" >> $BACKUP_DIR/config.uSys
    
    source $MOUNT_DIR1/config.uEnv
    # fdtfile=openvario-57-lvds.dtb
    echo "ROTATION=$rotation"
    case $(basename "$fdtfile" .dtb) in
        openvario-57-lvds)      HW_BASE="ch57";;
        openvario-7-CH070)      HW_BASE="ch70";;
        openvario-7-PQ070)      HW_BASE="pq70";;
        openvario-7-AM070-DS2)  HW_BASE="ds70";;
        openvario-43-rgb)       HW_BASE="am43";;
        *)
        echo "FDT file =  $fdtfile"
        fdtfile=${fdtfile##*/}
        echo "FDT file =  $fdtfile"
        HW_BASE=$(basename "${fdtfile%.*}")
        echo "FDT file =  $HW_BASE"
        HW_BASE=$(basename "${fdtfile}" ".${fdtfile##*.}")
        echo "FDT file =  $HW_BASE"
        HW_BASE="${s%.*}"
        echo "FDT file =  $HW_BASE"
        echo 
        read -rsp $'Press enter to continue...\n'
        HW_BASE="unknown";;
    esac
    # echo "HARDWARE=\"$(basename $fdtfile .dtb)\""
    echo "HARDWARE=\"$HW_BASE\""
    echo "HARDWARE=\"$HW_BASE\"" >> $BACKUP_DIR/config.uSys

    echo "ROTATION=\"$rotation\""
    echo "ROTATION=\"$rotation\"" >> $BACKUP_DIR/config.uSys
    # TEMP=$(grep "rotation" /boot/config.uEnv)

    echo "System Save End"
    #delete: read -rsp $'Press enter to continue...\n'
}

function start_upgrade(){
    # IMAGE_NAME=$(basename $IMAGEFILE)
#    echo "Start Upgrading with '$IMAGE_NAME'..."
    #================================
    # grep a number with exactly 5 digit: 
    # Comparism between HW_BASE  and HW_TARGET:
##aug!
    if [ ! "$HW_BASE" = "$HW_TARGET" ]; then
      TIMEOUT=20
      MENU_TITLE="Differenz between Update Target and Hardware '$HW_BASE'"
      MENU_TITLE="$MENU_TITLE\nVersion   $FW_VERSION"
      MENU_TITLE="$MENU_TITLE\nTarget    $TARGET"
      if [ -n "$TESTING" ]; then
        TESTING="Yes"
      else
        TESTING="No"
      fi
      MENU_TITLE="$MENU_TITLE\ntesting?  $TESTING"
      MENU_TITLE="$MENU_TITLE\nHW_BASE   $HW_BASE"
      MENU_TITLE="$MENU_TITLE\nHW_TARGET $HW_TARGET"
      MENU_TITLE="$MENU_TITLE\n=============================="
      MENU_TITLE="$MENU_TITLE\nDo you really want to upgrade to '$HW_TARGET'"
      dialog --nook --nocancel --pause \
      "$MENU_TITLE" \
      20 60 $TIMEOUT 2>&1
      # DO NOTHING AFTER USING '$?' ONE TIMES!!!
      
      # store the selection for debug reasons:
      INPUT="$?"
      if [ ! "$INPUT" = "0" ]; then
        echo "Exit!"
        # read -rsp $'Press enter to continue...\n'
        exit
      fi 
##aug!
    fi
    echo "Start Upgrading with '$IMAGE_NAME'..."
    
    # copy the ov-recovery.itb from HW folder for the next step!!!
    cp -f $OV_DIRNAME/images/$HW_TARGET/ov-recovery.itb    $OV_DIRNAME/ov-recovery.itb
    
    echo "FILENAME_TYPE: $FILENAME_TYPE  vs FW_VERSION: $FW_VERSION / HW_TARGET: $HW_TARGET"
    read -rsp $'Press enter to continue...\n'
    if [ "$FILENAME_TYPE" = "2" ] || [ $FW_VERSION -gt 23000 ]; then
      # copy the 1st block only if newer fw files
      # (and the BASE-FW is old...)
      echo "copy the 1st block (20MB) (boot-sector!)"
      # gzip -cfd $USB_STICK/BootPartition/BootSector16MB.gz | dd of=$TARGET bs=1M
      gzip -cfd ${IMAGEFILE} | dd of=$TARGET bs=1M count=20
    else
      dialog --nook --nocancel --pause "This is an old FW file ($FW_VERSION)!" 10 30 5 2>&1
    fi
    
    echo "Boot Recovery preparation with '${IMAGE_NAME}' finished!"
    if [ "$DEBUG_STOPS" = "y" ]; then
      # set outside in shell
      echo "Debug Stop: Finish"
      read -rsp $'Press enter to continue...\n'
    fi
    shutdown -r now
}

# Selecting image file:
select_image

# Complete Update
if [ -f "${IMAGEFILE}" ]; then
    echo "Start..."
    # make tmp dir clean:
    if [ -d "$SDC_DIR" ]; then
        chmod 757 -R $SDC_DIR
        rm -r $SDC_DIR
    fi

    # 1st: Save the system
    save_system
        # delete: echo "1st) mount partition 1"
    
        # delete: rm -rf $MOUNT_DIR1
    mkdir -p $BACKUP_DIR/part1
        # delete: mkdir -p $MOUNT_DIR1
        # delete: mount /dev/mmcblk0p1 $MOUNT_DIR1

    # 2nd: save boot folder to Backup from partition 1
    echo "2nd: save boot folder to Backup from partition 1"
    # cp -frv $MOUNT_DIR1/* $BACKUP_DIR/part1/
##aug!
    rsync -auv --progress $MOUNT_DIR1/* $BACKUP_DIR/part1/ --delete 
    #      --exclude ...

    # 3rd: save XCSoarData from partition 2:
    echo "3rd: save XCSoarData from partition 2"
        # delete: rm -rf $MOUNT_DIR2
        # delete: mkdir -p $MOUNT_DIR2
    mkdir -p $BACKUP_DIR/part2/xcsoar
        # delete: mount /dev/mmcblk0p2 $MOUNT_DIR2
    # cp -frv $MOUNT_DIR2/home/root/.xcsoar/* $BACKUP_DIR/part2/xcsoar/
##aug!    rsync -auv --progress $MOUNT_DIR2/home/root/.xcsoar/* $BACKUP_DIR/part2/xcsoar/ \
##aug!          --delete --exclude cache  --exclude logs
    
    if [ -d "$MOUNT_DIR2/home/root/.glider_club" ]; then
        echo "save gliderclub data from partition 2"
        mkdir -p $BACKUP_DIR/part2/glider_club
        cp -frv $MOUNT_DIR2/home/root/.glider_club/* $BACKUP_DIR/part2/glider_club/
    fi
    

    # Synchronize the commands (?)
    sync

    # pause:
    if [ "$DEBUG_STOPS" = "y" ]; then
      # set outside in shell
      echo "Debug Stop: After Saving"
      read -rsp $'Press enter to continue...\n'
    fi
    umount /dev/mmcblk0p1
    umount /dev/mmcblk0p2

    # BOOT_PARTITION=${IMAGEFILE}                                 # 1st
    echo "$IMAGEFILE" > $OV_DIRNAME/upgrade.file0.txt

    # Better as copy is writing the name in the 'upgrade file'
    echo "Firmware ImageFile = $IMAGE_NAME !"
    echo "$IMAGE_NAME" > $OV_DIRNAME/upgrade.file
    echo "$IMAGE_NAME" > $OV_DIRNAME/upgrade.file.txt

    echo "Upgrade step 1 finished!"
    chmod 757 -R $MNT_DIR
    rm -rf $MNT_DIR

    # echo "Upgrade with '${IMAGEFILE}'"
    if [ "$DEBUG_STOPS" = "y" ]; then
      # set outside in shell
      echo "Debug Stop: After Upgrade Step 1"
      read -rsp $'Press enter to continue...(4)\n'
    fi
    IMAGE_NAME=$(basename "$IMAGEFILE" .gz)
    TIMEOUT=5
    # DIALOG_CANCEL=1 
    dialog --nook --nocancel --pause \
    "OpenVario Upgrade with \\n'$IMAGE_NAME' ... \\n Press [ESC] for interrupting" \
    20 60 $TIMEOUT 2>&1
    # DO NOTHING AFTER USING '$?' ONE TIMES!!!
    
    # store the selection for debug reasons:
    INPUT="$?"
    case $INPUT in
        0) 
            start_upgrade;;
        *) echo "Upgrade interrupted!" ;;
    esac

else
    if [ "${IMAGEFILE}" = "" ]; then
        echo "IMAGEFILE is empty, no recovery!"
    else
        echo "'$IMAGE_NAME' don't exist, no recovery!"
    fi
fi
