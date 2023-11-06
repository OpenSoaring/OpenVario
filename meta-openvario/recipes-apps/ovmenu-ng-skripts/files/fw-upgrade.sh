#!/bin/bash

echo "Firmware Upgrade OpenVario"
echo "=========================="

DEBUG_STOP=""

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

# partition 1 of SD card is mounted as '/boot'!
MOUNT_DIR1=/boot
# partition 2 of SD card is mounted on the root of the system
MOUNT_DIR2=/

rsync --version > /dev/null
if [ "$?" -eq "0" ]; then
   RSYNC_COPY="ok"
fi

function debug_stop(){
    if [ -n "$DEBUG_STOP" ]; then
      echo "Debug-Stop"
      read -p "Press enter to continue"
    fi
}

BATCH_PATH=$(dirname $0)
echo "Batch Path = '$BATCH_PATH'"
source $BATCH_PATH/version_compare.sh

function select_image(){
    images=$OV_DIRNAME/images/O*V*-*.gz

    let i=0 # define counting variable
    files=()        # define file array 
    files_nice=()   # define array with index + file description for dialogdialog
    while read -r line; do # process file by file
        let i=$i+1
        files+=($i "$line")
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
    clear_display

    if [ ! -e "$IMAGEFILE" ]; then
        if [ -n $IMAGEFILE ]; then
            echo "no image file '$IMAGEFILE' found ... "
        fi
        exit
    else
        IMAGE_NAME="$(basename $IMAGEFILE)"
        TESTING=$(echo $IMAGE_NAME | grep -o "testing")
        # grep the buzzword 'testing'
        FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]{5}')
        if [ -n "$FW_VERSION" ]; then
            FILENAME_TYPE=1
            # find the part between '-ipk- and .rootfs
            teststr=$(echo $IMAGE_NAME | awk -F'-ipk-|.rootfs' '{print $2}')
            # teststr is now: 17119-openvario-57-lvds[-testing]
            hw_target=$(echo $teststr | awk -F'-openvario-|-testing' '{print $2}')
            case $hw_target in
                57lvds)       HW_TARGET="ch57";;
                57-lvds)      HW_TARGET="ch57";;
                7-CH070)      HW_TARGET="ch70";;
                7-PQ070)      HW_TARGET="pq70";;
                7-AM070-DS2)  HW_TARGET="ds70";;
                43-rgb)       HW_TARGET="am43";;
                *)            HW_TARGET="'$hw_target' (unknown)";;
            esac
        else
            # grep a version in form '##.##.##-##' like '3.0.2-20' 
            FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
            FILENAME_TYPE=2
            hw_target=$(echo $IMAGE_NAME | awk -F'-CB2-|.img' '{print $2}')
            # awk is splitting 'OV-3.0.2.20-CB2-CH57.img.gz' in:
            # OV-3.0.2.20', 'ch57', '.gz' (-CB2- and .img are cutted out) 
            # if [ $hw_target in ("ch57", ch70", pq70", ds70", am43") ]; then
            #  HW_TARGET="$hw_target"
            # else 
            case $hw_target in
                ch57)        HW_TARGET="$hw_target";;
                ch70)        HW_TARGET="$hw_target";;
                pq70)        HW_TARGET="$hw_target";;
                ds70)        HW_TARGET="$hw_target";;
                am43)        HW_TARGET="$hw_target";;

                CH57)        HW_TARGET="ch57";;
                CH70)        HW_TARGET="ch70";;
                PQ70)        HW_TARGET="pq70";;
                AM70_DS2)    HW_TARGET="ds70";;
                AM43)        HW_TARGET="am43";;
                *)           HW_TARGET="'$hw_target' (unknown)";;
            esac
            # fi
        fi
        echo "selected image file:    $IMAGE_NAME"
    fi
}


function clear_display(){
    #================== clear display (after diolog) =======================================================
    for ((i=1 ; i<=20 ; i++ )); do 
        echo ""
    done
}
    
function save_system(){
    #================== System Config =======================================================
    echo "1st: save system config in config.uSys for restoring reason"
    # 1st save system config in config.uSys for restoring reason
    mkdir -p $SDC_DIR
    
    # start with a new 'config.uSys':
    if [ -f /lib/systemd/system-preset/50-disable_dropbear.preset ]; then
        rm -f $SDC_DIR/config.uSys
        if /bin/systemctl --quiet is-enabled dropbear.socket; then
            echo "SSH=\"enabled\""
            echo "SSH=\"enabled\"" >> $SDC_DIR/config.uSys
        elif /bin/systemctl --quiet is-active dropbear.socket; then
            echo "SSH=\"temporary\""
            echo "SSH=\"temporary\"" >> $SDC_DIR/config.uSys
        else
            echo "SSH=\"disabled\""
            echo "SSH=\"disabled\"" >> $SDC_DIR/config.uSys
        fi
    else
        # if there no dropbear.preset found -> enable the SSH like in this
        # old fw version!
        echo "SSH=\"enabled\""
        echo "SSH=\"enabled\"" >> $SDC_DIR/config.uSys
    fi

    brightness=$(</sys/class/backlight/lcd/brightness)
    if [ -n brightness ]; then
      echo "BRIGHTNESS=\"$brightness\""
      echo "BRIGHTNESS=\"$brightness\"" >> $SDC_DIR/config.uSys
    else
      echo "'brightness' doesn't exist"
      echo "BRIGHTNESS=\"9\"" >> $SDC_DIR/config.uSys    
    fi 
    
    # if config.uEnv not exist
    if [ ! -f $MOUNT_DIR1/config.uEnv ]; then
        MOUNT_DIR1="/mnt/boot"
        mkdir -p $MOUNT_DIR1
        # $TARGET  = /dev/mmcblk0
        mount /dev/mmcblk0p1 $MOUNT_DIR1
        if [ ! -f $MOUNT_DIR1/config.uEnv ]; then
           echo "'$MOUNT_DIR1/config.uEnv' don't exist!?!"
           read -p "Press enter to continue"
        fi
    fi
    source $MOUNT_DIR1/config.uEnv
    # fdtfile=openvario-57-lvds.dtb
    if [ -z "$fdtfile" ]; then
      # this means, we have a (very) old version (< 21000 ?)
      echo "'$fdtfile' don't exist!?!"
      echo "What is to do???"
      VERSION_INFO=$(head -n 1 $MOUNT_DIR1/image-version-info)
      fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $3}')
      if [ -z "$fdtfile" ]; then fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $2}'); fi
      fdtfile="openvario-$fdtfile"
      echo "fdtfile = '$fdtfile'!!!!"
      read -p "Press enter to continue"
    
    fi
    case $(basename "$fdtfile" .dtb) in
        ov-ch57)      HW_BASE="ch57";;
        ov-ch70)      HW_BASE="ch70";;
        ov-pq70)      HW_BASE="pq70";;
        ov-ds70)      HW_BASE="ds70";;
        ov-am43)      HW_BASE="am43";;

        openvario-57-lvds)      HW_BASE="ch57";;
        openvario-7-CH070)      HW_BASE="ch70";;
        openvario-7-PQ070)      HW_BASE="pq70";;
        openvario-7-AM070-DS2)  HW_BASE="ds70";;
        openvario-43-rgb)       HW_BASE="am43";;
        *)                      HW_BASE="unknown";;
    esac
    echo "HARDWARE=\"$HW_BASE\""
    echo "HARDWARE=\"$HW_BASE\"" >> $SDC_DIR/config.uSys

    echo "ROTATION=\"$rotation\""
    echo "ROTATION=\"$rotation\"" >> $SDC_DIR/config.uSys

    #UpgradeType
    # 0 - from new fw to new fw
    # 1 - from previous fw to new fw
    # 2 - from new fw to previous fw
    # 3 - from previous fw to previous fw
    # 4 - from old fw (f.e. 17119) to new fw
    # 5 - from new fw to old fw
    # other types are not supported (f.e. old to previous an so on)!
    echo "UPGRADE_TYPE=\"0\"" >> $SDC_DIR/config.uSys
    echo "System Save End"
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
      MENU_TITLE="$MENU_TITLE\nTarget    $HW_TARGET"
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
      clear_display
      if [ ! "$INPUT" = "0" ]; then
        echo "Exit!"
        exit
      fi 

    fi
    echo "Start Upgrading with '$IMAGE_NAME'..."
    
    # copy the ov-recovery.itb from HW folder for the next step!!!
    if [ -z "$HW_TARGET" ]; then
      HW_TARGET="ch57"
    fi 

    if [ ! -f "/usr/bin/ov-recovery.itb" ]; then
      # only copy it if not available:
      case $UPDATE_TYPE in
          -1) 
             echo "This is not possible with UPDATE_TYPE: $UPDATE_TYPE"
             read -p "Press enter to continue"
             ;;
          0|*) # only for debug-test
             # debug: 
             read -p "Press enter to continue"
             ;;
      esac
      if [ -f "$OV_DIRNAME/images/$HW_TARGET/ov-recovery.itb" ]; then
        # hardlink fro FAT (USB-Stick..) is not possible 
        if [ -n "$RSYNC_COPY" ]; then
          rsync -auvtcE --progress  $OV_DIRNAME/images/$HW_TARGET/ov-recovery.itb    /usr/bin/ov-recovery.itb
        else
          echo "copy 'ov-recovery.itb' in the correct directory..."
          cp -f  $OV_DIRNAME/images/$HW_TARGET/ov-recovery.itb    /usr/bin/ov-recovery.itb
        fi
        echo "'ov-recovery.itb' done"
      fi
    fi
    if [ -f "/usr/bin/ov-recovery.itb" ]; then
        # hardlink from '/home/root/' to '/usr/bin/ov-recovery.itb'
        ln -f /usr/bin/ov-recovery.itb ov-recovery.itb
    fi
    if [ ! -f "ov-recovery.itb" ]; then
        echo "'ov-recovery.itb' don't exist - no upgrade possible"
        read -p "Press enter to continue"
        echo "Exit!"
        exit
    fi

    echo "FILENAME_TYPE: $FILENAME_TYPE  vs FW_VERSION: $FW_VERSION / HW_TARGET: $HW_TARGET"
    if [ "$FILENAME_TYPE" = "2" ] || [ $FW_VERSION -gt 23000 ]; then
      # copy the 1st block only if newer fw files
      # (and the BASE-FW is old...)
      echo "copy the 1st block (20MB) (boot-sector!)"
      gzip -cfd ${IMAGEFILE} | dd of=$TARGET bs=1M count=20
    else
      dialog --nook --nocancel --pause "This is an old FW file ($FW_VERSION)!" 10 30 5 2>&1
      clear_display
    fi
    
    echo "Boot Recovery preparation with '${IMAGE_NAME}' finished!"
    shutdown -r now
}

# check if usb dir exist and is mounted!
if [ ! -d $USB_STICK ]; then
  USB_STICK=/mnt/usb
  mkdir -p $USB_STICK
  mount /dev/sda1 $USB_STICK
  # or sdb1, sdc1, ...
  if [ ! -d $OV_DIRNAME ]; then
    echo "'$OV_DIRNAME' don't exist!?!"
    read -p "Press enter to continue"
  fi

fi 


# Selecting image file:
select_image

# Complete Update
if [ -f "${IMAGEFILE}" ]; then
    echo "Start..."
    # make tmp dir clean:
    if [ -d "$SDC_DIR" ]; then
        chmod 757 -R $SDC_DIR
        # don't delete, better to make 'with rsync --delete' rm -r $SDC_DIR
    fi
    
    if [ ! -f $MOUNT_DIR1/config.uEnv ]; then
      # sd partition 1 is not in boot gemounted...
      MOUNT_DIR1="/mnt/sd1"
      mkdir -p $MOUNT_DIR1
      
    fi

    # 1st: Save the system
    save_system


    # 2nd: save boot folder to Backup from partition 1
    echo "2nd: save boot folder to Backup from partition 1"
    mkdir -p $SDC_DIR/part1
    if [ -n "$RSYNC_COPY" ]; then
        rsync -ruvtcE --progress $MOUNT_DIR1/* $SDC_DIR/part1/ --delete 
        echo "'ov-recovery.itb' done"
    else
        echo "  copy command (rsync not available)..."
        # this is possible on older fw (17119 for example)
        rm -fr $SDC_DIR/part1/*
        cp -rfv  $MOUNT_DIR1/* $SDC_DIR/part1/
    fi
    #      --exclude ...

    # 3rd: save XCSoarData from partition 2:
    echo "3rd: save XCSoarData from partition 2"
    # mkdir -p $SDC_DIR/part2/XCSoarData

    if [ -n "$RSYNC_COPY" ]; then
        # mkdir -p $SDC_DIR/part2/xcsoar
        rsync -ruvtcE --progress $MOUNT_DIR2/home/root/.xcsoar/* $SDC_DIR/part2/xcsoar/ \
              --delete --exclude cache  --exclude logs
        rsync -uvtcE --progress $MOUNT_DIR2/home/root/.bash_history $SDC_DIR/part2/
    else
        echo "  copy command (rsync not available)..."
        # this is possible on older fw (17119 for example)
        rm -fr $SDC_DIR/part2/*
        mkdir -p $SDC_DIR/part2/xcsoar
        cp -rfv  $MOUNT_DIR2/home/root/.xcsoar/* $SDC_DIR/part2/xcsoar/
        cp -fv   $MOUNT_DIR2/home/root/.bash_history $SDC_DIR/part2/
    fi
    debug_stop

    # HardLink at FAT isn't possible
    if [ -d "$MOUNT_DIR2/home/root/.glider_club" ]; then
        echo "save gliderclub data from partition 2"
        mkdir -p $SDC_DIR/part2/glider_club
        cp -frv $MOUNT_DIR2/home/root/.glider_club/* $SDC_DIR/part2/glider_club/
    fi
    
    # Synchronize the commands (?)
    sync

    # Better as copy is writing the name in the 'upgrade file'
    echo "Firmware ImageFile = $IMAGE_NAME !"
    echo "$IMAGE_NAME" > $OV_DIRNAME/upgrade.file

    echo "Upgrade step 1 finished!"
    chmod 757 -R $MNT_DIR
    rm -rf $MNT_DIR

    IMAGE_NAME=$(basename "$IMAGEFILE" .gz)
    TIMEOUT=5
    dialog --nook --nocancel --pause \
    "OpenVario Upgrade with \\n'$IMAGE_NAME' ... \\n Press [Enter] or wait $TIMEOUT seconds to continue\\n Press [ESC] for interrupting" \
    20 60 $TIMEOUT 2>&1
    # DO NOTHING AFTER USING '$?' ONE TIMES!!!
    
    # store the selection for debug reasons:
    INPUT="$?"
    clear_display
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
