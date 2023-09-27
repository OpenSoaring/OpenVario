#!/bin/bash

echo "Firmware Upgrade OpenVario"
echo "=========================="

# USB_STICK=usb
USB_STICK=/usb/usbstick

DIALOG_CANCEL=1

# the OV dirname at USB stick
OV_DIRNAME=$USB_STICK/openvario

# temporary directories at USB stick to save the setting informations
SDC_DIR=$OV_DIRNAME/sdcard
MNT_DIR="mnt"
# MNT_DIR=$OV_DIRNAME/usb

# SD card:
TARGET=/dev/mmcblk0
IMAGEFILE=""

BACKUP_DIR=$SDC_DIR
MOUNT_DIR1=$MNT_DIR/part1
MOUNT_DIR2=$MNT_DIR/part2

mkdir

BOOT_PARTITION=$USB_STICK/BootPartition/BootSector16MB.gz   # 2nd option
BOOT_PARTITION=$OV_DIRNAME/BootSector.gz                    # 3rd option

function select_image(){
    images=$OV_DIRNAME/images/O*V*-*.gz

    let i=0 # define counting variable
    files=() # define working array
    files_nice=()
    while read -r line; do # process file by file
        let i=$i+1
        files+=($i "$line")
        filename=$(basename "$line") 
        # OpenVario-linux
        temp1=$(echo $line | grep -oE '[0-9]{5}')
        if [ -n "$temp1"]; then
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
    
    if [ -n "$files" ]; then
        # Search for images
        FILE=$(dialog --backtitle "Selection upgrade image from file list" \
        --title "Select image" \
        --menu "Use [UP/DOWN] keys to move, ENTER to select" \
        18 60 12 \
        "${files_nice[@]}" 3>&2 2>&1 1>&3)
        
        IMAGEFILE=$(readlink -f $(ls -1 $images |sed -n "$FILE p"))
    else
        FILE=""
    fi

    if [ ! -e "$IMAGEFILE" ]; then
        dialog --backtitle "${TITLE}" \
        --title "Select image" \
        --msgbox "\n\n No image file found !!" 10 40
        exit
    else
        echo "selected image file:    $IMAGEFILE"
    fi
    
}


function start_upgrade(){
    if [ "$HW_CONFIG" == "" ]; then
       HW_CONFIG="ch57"
    fi
    # rename the ov-recovery.itx to ov-recovery.itb for the next step!!!
    cp -f $OV_DIRNAME/images/$HW_CONFIG/ov-recovery.itb    $OV_DIRNAME/ov-recovery.itb

    echo "copy the 1st block (20MB) (boot-sector!)"
    # gzip -cfd $USB_STICK/BootPartition/BootSector16MB.gz | dd of=$TARGET bs=1M
    gzip -cfd ${BOOT_PARTITION} | dd of=$TARGET bs=1M count=20

    echo "Boot Recovery preparation with '${IMAGEFILE}' finished!"
    if [ "$DEBUG_STOPS" == "y" ]; then
      # set outside in shell
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

    # save boot folder to Backup from partition 1
    echo "save boot folder to Backup from partition 1"
    rm -rf $MOUNT_DIR1
    mkdir -p $BACKUP_DIR/part1
    mkdir -p $MOUNT_DIR1
    mount /dev/mmcblk0p1 $MOUNT_DIR1
    cp -frv $MOUNT_DIR1/* $BACKUP_DIR/part1/

    # save XCSoarData from partition 2:
    echo "save XCSoarData from partition 2"
    rm -rf $MOUNT_DIR2
    mkdir -p $MOUNT_DIR2
    mkdir -p $BACKUP_DIR/part2/xcsoar
    mount /dev/mmcblk0p2 $MOUNT_DIR2
    cp -frv $MOUNT_DIR2/home/root/.xcsoar/* $BACKUP_DIR/part2/xcsoar/
    
    if [ -d "$MOUNT_DIR2/home/root/.glider_club" ]; then
        echo "save gliderclub data from partition 2"
        mkdir -p $BACKUP_DIR/part2/glider_club
        cp -frv $MOUNT_DIR2/home/root/.glider_club/* $BACKUP_DIR/part2/glider_club/
    fi
    
    #================== System Config =======================================================
    #save system config in config.uSys for restoring reason
    echo "" > $BACKUP_DIR/config.uSys
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
    # echo "ROTATION=\"$(</sys/class/graphics/fbcon/rotate_all)\""
    # echo "ROTATION=\"$(</sys/class/graphics/fbcon/rotate_all)\"" >> $BACKUP_DIR/config.uSys
    
    source $MOUNT_DIR1/config.uEnv
    case $(basename $fdtfile .dtb) in
        openvario-57-lvds)      hw_config="ch57";;
        openvario-7-CH070)      hw_config="ch70";;
        openvario-7-PQ070)      hw_config="pq70";;
        openvario-7-AM070-DS2)  hw_config="ds70";;
        openvario-43-rgb)       hw_config="am43";;
        *)                      hw_config="ch57";;
    esac
    # echo "HARDWARE=\"$(basename $fdtfile .dtb)\""
    echo "HARDWARE=\"$hw_config\""
    echo "HARDWARE=\"$hw_config\"" >> $BACKUP_DIR/config.uSys

    echo "ROTATION=\"$rotation\""
    echo "ROTATION=\"$rotation\"" >> $BACKUP_DIR/config.uSys
    # TEMP=$(grep "rotation" /boot/config.uEnv)

    # Synchronize the commands (?)
    sync


    # pause:
    if [ "$DEBUG_STOPS" == "y" ]; then
      # set outside in shell
      read -rsp $'Press enter to continue...\n'
    fi
    umount /dev/mmcblk0p1
    umount /dev/mmcblk0p2

    BOOT_PARTITION=${IMAGEFILE}                                 # 1st
    echo "$IMAGEFILE" > $OV_DIRNAME/upgrade.file0.txt
    echo "${IMAGEFILE//"$OV_DIRNAME/images"/""}" > $OV_DIRNAME/upgrade.file1.txt
    #     echo "${IMAGEFILE//"$MNT_DIR/"/mnt"}" > $OV_DIRNAME/upgrade.file2.txt
    # remove path:
    # IMAGEFILE=${IMAGEFILE//"$OV_DIRNAME/images"/""}
    IMAGEFILE=$(basename $IMAGEFILE)

    # Better as copy is writing the name in the 'upgrade file'
    echo "Firmware ImageFile = $IMAGEFILE !"
    echo "$IMAGEFILE" > $OV_DIRNAME/upgrade.file
    echo "$IMAGEFILE" > $OV_DIRNAME/upgrade.file.txt

    echo "Upgrade step 1 finished!"
    chmod 757 -R $MNT_DIR
    rm -rf $MNT_DIR

    # echo "Upgrade with '${IMAGEFILE}'"
    if [ "$DEBUG_STOPS" == "y" ]; then
      # set outside in shell
      read -rsp $'Press enter to continue...(4)\n'
    fi
    IMAGENAME=$(basename "$IMAGEFILE" .gz)
    TIMEOUT=5
    dialog --nook --nocancel --pause "OpenVario Upgrade with \\n'${IMAGENAME}' ... \\n Press [ESC] for interrupting" 20 60 $TIMEOUT 2>&1

    # Synchronize the commands (?)
    sync

    case $? in
        0) start_upgrade;;
        *) echo "Upgrade interrupted!";;
    esac

else
    echo "'${IMAGEFILE}' don't exist, no recovery!"
fi
