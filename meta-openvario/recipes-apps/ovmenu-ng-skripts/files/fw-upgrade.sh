#!/bin/bash

if [ -z "$1" ]; then
  echo "1st call '$0'"
else
  echo "2nd call '$0' - with '$1'"
fi

DEBUG_STOP="No"
VERBOSE=n

USB_STICK=/usb/usbstick
DIALOG_CANCEL=1
SELECTION=/tmp/output.sh.$$
USB_OPENVARIO=""

# timestamp > OV-3.0.1-19-CB2-XXXX.img.gz
TIMESTAMP_3_19=1695000000

# MNT_DIR="mnt"
# MNT_DIR=$USB_OPENVARIO/usb

# SD card:
TARGET=/dev/mmcblk0
IMAGEFILE=""
TARGET_HW="0000"
TARGET_FILENAME_TYPE=0
TARGET_FW_VERSION=0
BASE_HW="0000"
BASE_FW_VERSION=0
UPGRADE_TYPE=0

# partition 1 of SD card is mounted as '/boot'!
PARTITION1=/boot
# partition 2 of SD card is mounted on the root of the system
PARTITION2_ROOT=/home/root
# partition 3 of SD card is mounted on the root of the system
PARTITION3=$PARTITION2_ROOT/data

UPGRADE_CFG=$PARTITION1/upgrade.cfg
# UPGRADE_CFG=$UPGRADE_CFG

# temporary directories at USB stick to save the setting informations
RECOVER_DIR=""
BACKUP_DIR=""
WITH_FW_BACKUP=No
WITH_DATA_BACKUP=No

BATCH_PATH=$(dirname $0)
if [ -z "$1" ]; then
  $0 "Das ist ein Versuch mit '$PARTITION1/upgrade.cfg'"
  # if you call this a 2nd time (with a newer file...) don't make it again
  exit
fi
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
function printv(){
    if [ "$VERBOSE" = "y" ]; then
      echo "$1"
    fi
}

#------------------------------------------------------------------------------
vercomp () {
    printv "compare '$1' vs. '$2'"
    printv "---------------------"
    if [[ $1 == $2 ]]
    then
        # debug_stop "equal!"
        return 0 # equal
    fi
    local IFS='.'
    local i ver1 ver2
    # replace '-' with '.' and split it an array
    IFS='.' read -ra ver1 <<< "$1"
    IFS='.' read -ra ver2 <<< "$2"
    for ((i=0; i<4; i++))
    do
        # fill empty fields in ver1 with zeros
        if [ -z ${ver1[i]} ]; then ver1[i]=0; fi
        if [ -z ${ver2[i]} ]; then ver2[i]=0; fi
    done
    
    if (( ${#ver1[0]} > 4 ))
    then
       # with fw 17119 make version 0.17119 for a correct compare
            ver1[1]=${ver1[0]}
            ver1[0]=0
    fi
    if (( ${#ver2[0]} > 4 ))
    then
       # with fw 17119 make version 0.17119 for a correct compare
            ver2[1]=${ver2[0]}
            ver2[0]=0
    fi

    ## for ((i=0; i<4; i++))
    ## do
    ##     echo ${ver1[i]}  ${ver2[i]}
    ## done

    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((${ver1[i]} > ${ver2[i]}))
        then
            # debug_stop "greater then"
            return 2 # greater 
        fi
        if ((${ver1[i]} < ${ver2[i]}))
        then
            # debug_stop "lower then"
            return 1 # lower
        fi
    done
    # debug_stop "equal?"
    return 0 # equal
}

#------------------------------------------------------------------------------
function select_image(){
    # images=$USB_OPENVARIO/images/O*V*-*.gz
    images=data/images/O*V*-*.gz

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
    images=$USB_OPENVARIO/images/O*V*-*.gz
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
        files_nice+=($count "$temp (USB)") # selection index + name
    done < <( ls -1 $images )
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
        echo "no image file(s) found"
        IMAGEFILE=""
    fi
    clear_display

    if [ ! -e "$IMAGEFILE" ]; then
        if [ -n "$IMAGEFILE" ]; then
            echo "no image file '$IMAGEFILE' available ... "
        fi
        exit
    else
        IMAGE_NAME="$(basename $IMAGEFILE)"
        TESTING=$(echo $IMAGE_NAME | grep -o "testing")
        # grep the buzzword 'testing'
        TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]{5}')
        if [ -n "$TARGET_FW_VERSION" ]; then
            TARGET_FILENAME_TYPE=1
            # find the part between '-ipk- and .rootfs
            teststr=$(echo $IMAGE_NAME | awk -F'-ipk-|.rootfs' '{print $2}')
            # teststr is now: 17119-openvario-57-lvds[-testing]
            TARGET_HW=$(echo $teststr | awk -F'-openvario-|-testing' '{print $2}')
            case $TARGET_HW in
                57lvds)       TARGET_HW="CH57";;
                57-lvds)      TARGET_HW="CH57";;
                7-CH070)      TARGET_HW="CH70";;
                7-PQ070)      TARGET_HW="PQ70";;
                7-AM070-DS2)  TARGET_HW="AM70s";;
                43-rgb)       TARGET_HW="AM43";;
                *)            TARGET_HW="'$TARGET_HW' (unknown)";;
            esac
        else
            # grep a version in form '##.##.##-##' like '3.0.2-20' 
            TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
            TARGET_FW_TYPE=1
            if [ -z "$TARGET_FW_VERSION" ]; then
              # ... or in form '##.##.##.##' like '3.2.20.1' 
              TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+')
              TARGET_FW_TYPE=2
            fi
            if [ -z "$TARGET_FW_VERSION" ]; then
              # ... or in form '##.##.##' like '3.0.2' 
              TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+')
              TARGET_FW_TYPE=2
            fi
            TARGET_FILENAME_TYPE=2
            TARGET_HW=$(echo $IMAGE_NAME | awk -F'-CB2-|.img' '{print $2}')
            # awk is splitting 'OV-3.0.2.20-CB2-CH57.img.gz' in:
            # OV-3.0.2.20', 'CH57', '.gz' (-CB2- and .img are cutted out) 
            # if [ $TARGET_HW in ("CH57", CH70", PQ70", AM70s", AM43") ]; then
            #  TARGET_HW="$TARGET_HW"
            # else 
            case $TARGET_HW in
                CH57)        TARGET_HW="$TARGET_HW";;
                CH70)        TARGET_HW="$TARGET_HW";;
                PQ70)        TARGET_HW="$TARGET_HW";;
                AM70s)       TARGET_HW="$TARGET_HW";;
                AM43)        TARGET_HW="$TARGET_HW";;

                AM70_DS2)    TARGET_HW="AM70s";;
                *)           TARGET_HW="'$TARGET_HW' (unknown)";;
            esac
            # fi
        fi
        echo "selected image file:      '$IMAGE_NAME'"
        echo "TARGET_FW_VERSION:        '$TARGET_FW_VERSION'"
        echo "TARGET_FW_TYPE:           '$TARGET_FW_TYPE'"
        echo "TARGET_HW:                '$TARGET_HW'"
        echo "TARGET_FILENAME_TYPE:     '$TARGET_FILENAME_TYPE'"
        debug_stop
    fi
    # 0 - equal, 1 - lower, 2 greater
    printv "1) '$BASE_FW_VERSION' => '$TARGET_FW_VERSION'"
    vercomp "${TARGET_FW_VERSION//-/.}" "3.2.19"
    FW_TYPE_TARGET=$?
    vercomp   "${BASE_FW_VERSION//-/.}"   "3.2.19"
    FW_TYPE_BASE=$?
    printv "2) '$FW_TYPE_BASE' => '$FW_TYPE_TARGET'"
    if [ "$FW_TYPE_TARGET" = "2" ]; then
      if [ "$FW_TYPE_BASE" = "2" ]; then
        UPGRADE_TYPE=1  # 1- from new fw to new fw
      else
        UPGRADE_TYPE=2  # 2 - from old fw to new fw
      fi
    else
      if [ "$FW_TYPE_BASE" = "2" ]; then
        UPGRADE_TYPE=3 # 3 - from new fw to old fw
      else
        UPGRADE_TYPE=4 # 4 - from old fw to old fw
      fi
    fi
    debug_stop "3) '$FW_TYPE_BASE' => '$FW_TYPE_TARGET' = UPGRADE_TYPE '$UPGRADE_TYPE'"
}


#------------------------------------------------------------------------------
function clear_display(){
    #================== clear display (after diolog) =======================================================
    for ((i=1 ; i<=20 ; i++ )); do 
        echo ""
    done
}
   

#------------------------------------------------------------------------------
function detect_base() {
    # if config.uEnv not exist
    if [ ! -f $PARTITION1/config.uEnv ]; then
        PARTITION1="/mnt/boot"
        mkdir -p $PARTITION1
        # $TARGET  = /dev/mmcblk0
        mount /dev/mmcblk0p1 $PARTITION1
        if [ ! -f $PARTITION1/config.uEnv ]; then
           error_stop "'$PARTITION1/config.uEnv' don't exist!?!"
        fi
    fi
    source $PARTITION1/config.uEnv

    # read 1st line in 'image-version-info'
    VERSION_INFO=$(head -n 1 $PARTITION1/image-version-info)
    if [ -z "$fdtfile" ]; then
      # this means, we have a (very) old version (< 21000 ?)
      printv "'$fdtfile' don't exist!?!"
      printv "What is to do???"
      # VERSION_INFO=$(head -n 1 $PARTITION1/image-version-info)
      fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $3}')
      if [ -z "$fdtfile" ]; then fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $2}'); fi
      fdtfile=$(echo $fdtfile | awk -F'-201|202' '{print $1}')
      fdtfile="openvario-$fdtfile"
      BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]{5}')
      BASE_FILENAME_TYPE=1
      debug_stop "fdtfile = '$fdtfile'!!!!"
    else
      # 3.2.21:
      BASE_FILENAME_TYPE=0
      BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]+[.][0-9]+[.][0-9]+')
      if [ -z "$BASE_FW_VERSION" ]; then
      # 3.0.1-19:
        BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
        BASE_FW_TYPE=1
      else
        BASE_FW_TYPE=2
      fi
      # 3.2.20.1
      if [ -z "$BASE_FW_VERSION" ]; then
        BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+')
        BASE_FW_TYPE=2
      fi
      if [ -z "$BASE_FW_VERSION" ]; then
        # this could be up to version 3.39.19 ( = '23229')
        BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]{5}')
        if [ -n "$BASE_FW_VERSION" ]; then BASE_FILENAME_TYPE=1; fi
        BASE_FW_TYPE=1
      else 
        BASE_FILENAME_TYPE=2
      fi
    fi
    if [ -z "$BASE_FW_VERSION" ]; then
        error_stop "BASE_FW_VERSION is empty!!!!"
    fi    
    case $(basename "$fdtfile" .dtb) in
        ov-ch57)      BASE_HW="CH57";;
        ov-ch70)      BASE_HW="CH70";;
        ov-pq70)      BASE_HW="PQ70";;
        ov-am70s)     BASE_HW="AM70s";;
        ov-am43)      BASE_HW="AM43";;

        openvario-57lvds)       BASE_HW="CH57";;
        openvario-57-lvds)      BASE_HW="CH57";;
        openvario-7-CH070)      BASE_HW="CH70";;
        openvario-7-PQ070)      BASE_HW="PQ70";;
        openvario-7-AM070-DS2)  BASE_HW="AM70s";;
        openvario-43-rgb)       BASE_HW="AM43";;
        *)                      BASE_HW="unknown";;
    esac
    echo "HARDWARE=\"$BASE_HW\""
        echo "selected Base:          '$VERSION_INFO'"
        echo "BASE_FW_VERSION:        '$BASE_FW_VERSION'"
        echo "BASE_FW_TYPE:           '$BASE_FW_TYPE'"
        echo "BASE_HW:                '$BASE_HW'"
        echo "BASE_FILENAME_TYPE:     '$BASE_FILENAME_TYPE'"
        debug_stop
}   
#------------------------------------------------------------------------------
function fw_backup() {
    # start with a new 'upgrade.
    #-------------------------------- August2111------------------------------
        if [ -d "$BACKUP_DIR" ]; then
          rm -fvr $BACKUP_DIR/*
          # echo "Backup 1st 20MB"
          # gzip -cfd ${IMAGEFILE} | dd of=$BACKUP_DIR/dd_test.bin.gz bs=1M count=20
          echo "Backup 1st 2MB"  # address 0 to partition 1 (FAT16)
          # dd of=$BACKUP_DIR/dd_test.bin bs=1024 count=2048
          gzip -cfd ${IMAGEFILE} | dd of=$BACKUP_DIR/root.bin bs=1024 count=2048 # = 2MB
          gzip $BACKUP_DIR/root.bin
          
          # mkdir -p $BACKUP_DIR/backup
          if [ "$UPGRADE_TYPE" = "1" ]; then  # with new to new only
            if [ "$WITH_DATA_BACKUP" = "Yes" ]; then
              # backup dir is on partition 3
              # dd if=/dev/mmcblk0 | gzip > $BACKUP_DIR/backup.img.gz bs=1024 count=524288 # = 512MB
              echo "Backup boot, partition1 and partition 2"
              dd if=/dev/mmcblk0  bs=1024 count=524288 | gzip >$BACKUP_DIR/backup.img.gz   # max: 512MB
              # zip data dir:
              echo "Backup Open- and XCSoarData"
              tar cvf - $PARTITION3/OpenSoarData | gzip >$BACKUP_DIR/OpenSoarData.tar.gz
              tar cvf - $PARTITION3/XCSoarData | gzip >$BACKUP_DIR/XCSoarData.tar.gz
            fi
          else  # all other upgrade types
            if [ "$WITH_FW_BACKUP" = "Yes" ]; then
              dd if=/dev/mmcblk0  bs=1024 count=4194304 | gzip >$BACKUP_DIR/backup.img.gz   # max: 4GB
            fi
            if [ "$WITH_DATA_BACKUP" = "Yes" ]; then
              # if [ "$FW_TYPE_BASE" = "2" ]; then  # with new to new only
              echo "Backup XCSoarData to xcsoar"
              if [ -d "$PARTITION3/OpenSoarData" ]; then  # with new to new only
                # which is the current?
                # tar cvf - $PARTITION3/XCSoarData | gzip >$BACKUP_DIR/xcsoar.tar.gz
                tar cvf - $PARTITION3/OpenSoarData | gzip >$BACKUP_DIR/xcsoar.tar.gz
              else
                tar cvf - $PARTITION2_ROOT/.xcsoar | gzip >$BACKUP_DIR/xcsoar.tar.gz
              fi
            fi
          fi 
          sync
        fi
        
        # August2111:
        # exit
    
    ### if [ "$UPGRADE_TYPE" = "1" ]; then  # with new to new only
    ### else  # all other upgrade types
    ### fi 
        #-------------------------------- August2111------------------------------
}
#------------------------------------------------------------------------------
function save_system(){
    #================== System Config =======================================================
    echo "1st: save system config in upgrade.cfg for restoring reason"
    # 1st save system config in upgrade.cfg for restoring reason
    
    if [ "$UPGRADE_TYPE" = "1" ]; then  # with new to new only
       SAVE_DIR="$PARTITION3"
    else  # all other upgrade types
       SAVE_DIR="$USB_OPENVARIO"
    fi 
    RECOVER_DIR="$SAVE_DIR/recover_data"
    BACKUP_DIR="$SAVE_DIR/backup/$(date +%y_%m_%d)"
    #-----------------------------------------------    
    debug_stop "RECOVER_DIR  = $RECOVER_DIR"
    mkdir -p $RECOVER_DIR
    mkdir -p $BACKUP_DIR
    
    rm -f $UPGRADE_CFG
    if [ -f /lib/systemd/system-preset/50-disable_dropbear.preset ]; then
        if /bin/systemctl --quiet is-enabled dropbear.socket; then
            echo "SSH=\"enabled\""
            echo "SSH=\"enabled\"" >> $UPGRADE_CFG
        elif /bin/systemctl --quiet is-active dropbear.socket; then
            echo "SSH=\"temporary\""
            echo "SSH=\"temporary\"" >> $UPGRADE_CFG
        else
            echo "SSH=\"disabled\""
            echo "SSH=\"disabled\"" >> $UPGRADE_CFG
        fi
    else
        # if there no dropbear.preset found -> enable the SSH like in this
        # old fw version!
        echo "SSH=\"enabled\""
        echo "SSH=\"enabled\"" >> $UPGRADE_CFG
    fi

    tar cvf - /var/lib/connman | gzip >$RECOVER_DIR/connman.tar.gz

    brightness=$(</sys/class/backlight/lcd/brightness)
    if [ -n brightness ]; then
      echo "BRIGHTNESS=\"$brightness\""
      echo "BRIGHTNESS=\"$brightness\"" >> $UPGRADE_CFG
    else
      echo "'brightness' doesn't exist"
      echo "BRIGHTNESS=\"9\"" >> $UPGRADE_CFG    
    fi 

    # TODO: with which firmware there was the change?
    vercomp "${TARGET_FW_VERSION//-/.}" "22000"
    TARGET_ROT_TEST=$?
    vercomp   "${BASE_FW_VERSION//-/.}"   "22000"
    BASE_ROT_TEST=$?
    if [ "$BASE_ROT_TEST" = "$TARGET_ROT_TEST" ]; then
      echo "FirmWare types identical: $BASE_ROT_TEST vs $TARGET_ROT_TEST!"
    else
      echo "FirmWare types different: $BASE_ROT_TEST vs $TARGET_ROT_TEST!"
      case $rotation in 
      0) rotation=0;;
      1) rotation=3;;
      2) rotation=2;;
      3) rotation=1;;
      esac 
    fi

    echo "ROTATION=\"$rotation\""
    echo "ROTATION=\"$rotation\"" >> $UPGRADE_CFG
    echo "System Save End"

    echo "HARDWARE_BASE=\"$BASE_HW\"" >> $UPGRADE_CFG
    echo "FIRMWARE_BASE=\"$BASE_FW_VERSION\"" >> $UPGRADE_CFG
    echo "FW_TYPE_BASE=\"$FW_TYPE_BASE\"" >> $UPGRADE_CFG

    echo "HARDWARE_TARGET=\"$TARGET_HW\"" >> $UPGRADE_CFG
    echo "FIRMWARE_TARGET=\"$TARGET_FW_VERSION\"" >> $UPGRADE_CFG
    echo "FW_TYPE_TARGET=\"$FW_TYPE_TARGET\"" >> $UPGRADE_CFG
    # UpgradeType:
    # 1- from new fw to new fw
    # 2 - from old fw to new fw
    # 3 - from new fw to old fw
    # 4 - from old fw to old fw
    # other types are not supported (f.e. old to previous an so on)!
    echo "UPGRADE_TYPE=\"$UPGRADE_TYPE\"" >> $UPGRADE_CFG
    
    fw_backup
    echo "WITH_DATA_BACKUP=\"$WITH_DATA_BACKUP\"" >> $UPGRADE_CFG
    
}

#------------------------------------------------------------------------------
function start_upgrade(){
    # IMAGE_NAME=$(basename $IMAGEFILE)
#    echo "Start Upgrading with '$IMAGE_NAME'..."
    #================================
    # grep a number with exactly 5 digit: 
    # Comparism between BASE_HW  and TARGET_HW:
##aug!
    if [ ! "$BASE_HW" = "$TARGET_HW" ]; then
      TIMEOUT=20
      MENU_TITLE="Differenz between Update Target and Hardware '$BASE_HW'"
      MENU_TITLE="$MENU_TITLE\nVersion   $TARGET_FW_VERSION"
      MENU_TITLE="$MENU_TITLE\nTarget    $TARGET_HW"
      if [ -n "$TESTING" ]; then
        TESTING="Yes"
      else
        TESTING="No"
      fi
      MENU_TITLE="$MENU_TITLE\ntesting?  $TESTING"
      MENU_TITLE="$MENU_TITLE\nBASE_HW   $BASE_HW"
      MENU_TITLE="$MENU_TITLE\nTARGET_HW $TARGET_HW"
      MENU_TITLE="$MENU_TITLE\n=============================="
      MENU_TITLE="$MENU_TITLE\nDo you really want to upgrade to '$TARGET_HW'"
      dialog --nook --nocancel --pause \
      "$MENU_TITLE" \
      20 60 $TIMEOUT 2>&1
      # DO NOTHING AFTER USING '$?' ONE TIMES!!!
      
      # store the selection for debug reasons:
      INPUT="$?"
      clear_display
      if [ ! "$INPUT" = "0" ]; then
        error_stop "Exit because Escape!"
        exit
      fi 

    fi
    echo "Start Upgrading with '$IMAGE_NAME'..."
    
    # copy the ov-recovery.itb from HW folder for the next step!!!
    if [ -z "$TARGET_HW" ]; then
      TARGET_HW="CH57"
    fi 

    if [ ! -f "/usr/bin/ov-recovery.itb" ]; then
      echo "this is an old firmware"
      ITB_TARGET=$USB_OPENVARIO/ov-recovery.itb
      ### ITB_TARGET=./ov-recovery.itb
      if [ -f "$USB_OPENVARIO/images/$TARGET_HW/ov-recovery.itb" ]; then
        # hardlink from FAT (USB-Stick..) is not possible 
        echo "copy 'ov-recovery.itb' in the correct directory..."
        cp -fv $USB_OPENVARIO/images/$TARGET_HW/ov-recovery.itb   $ITB_TARGET
        echo "'ov-recovery.itb' done"
      fi
      if [ ! -f "$ITB_TARGET" ]; then
            error_stop "'ov-recovery.itb' doesn't exist - no upgrade possible"
            echo "Exit!"
            exit
      fi
    else
        echo "'/usr/bin/ov-recovery.itb' is available" # AugTest
        # hardlink from '/home/root/' to '/usr/bin/ov-recovery.itb'
        ln -f /usr/bin/ov-recovery.itb ov-recovery.itb
        echo "ln -f /usr/bin/ov-recovery.itb ov-recovery.itb"
        if [ ! -f "ov-recovery.itb" ]; then
            error_stop "'ov-recovery.itb' doesn't exist - no upgrade possible"
            echo "Exit!"
            exit
        fi
    fi
    
    
    debug_stop "AugTest UPGRADE_TYPE = '$UPGRADE_TYPE'"
    case "$UPGRADE_TYPE" in
    1)  # - from new fw to new fw
        echo "both FW are a new type!"
    ;;
    2)  # - from old fw to new fw
        echo "Target FW is new but Base FW is old!"
        echo "copy the 1st block (20MB) (boot-sector!)"
        gzip -cfd ${IMAGEFILE} | dd of=$TARGET bs=1024 count=512
    ;;
    3)  # - from new fw to old fw
        echo "Target FW is old but Base FW is new!"
        dialog --nook --nocancel --pause "This is a change to an old FW file ($TARGET_FW_VERSION)!" 10 30 5 2>&1
        clear_display
    ;;
    4)  # - from old fw to old fw
        echo "both FW are a old type!"
        boot_sector_file=$USB_OPENVARIO/images/$TARGET_HW/bootsector.bin.gz
        if [ -e "$boot_sector_file" ]; then
          echo "copy bootsector file to bootsector"
          gzip -cfd $boot_sector_file | dd of=$TARGET bs=1024 count=512
        else
          error_stop "An upgrade without '$boot_sector_file' is not possible!"
        fi
    ;;
    esac
    
    echo "Boot Recovery preparation with '${IMAGE_NAME}' finished!"
    echo "========================================================"
    # Test:!!!!
    debug_stop
    shutdown -r now
}

#==============================================================================
#==============================================================================
#==============================================================================
echo "Firmware Upgrade OpenVario"
echo "=========================="

echo "Batch Path = '$BATCH_PATH'"
detect_base

if [ ! -d "$USB_STICK" ]; then
  # this could be at 17119 FW..
  USB_STICK=/usb
fi

# the OV dirname at USB stick
USB_OPENVARIO=$USB_STICK/openvario
stat

if [ ! -e "$PARTITION1/config.uEnv" ]; then
  umount boot >> /dev/null 2>&1
  mount ${TARGET}p1 boot
  if [ ! -e "$PARTITION1/config.uEnv" ]; then
    echo "No partition1 mounted - no upgrade possible"
    error_stop "==> exit"
  fi

fi

rsync --version > /dev/null 2>&1 || echo "No rsync available!"
if [ "$?" -eq "0" ]; then
   RSYNC_COPY="ok"
fi


# check if usb dir exist and is mounted!
if [ -b "/dev/sda1" ]; then
  if [ ! -d $USB_STICK ]; then
    USB_STICK=/mnt/usb
    echo "USB stick will be mounted on '$USB_STICK'"
    mkdir -p $USB_STICK
    mount /dev/sda1 $USB_STICK
    # or sdb1, sdc1, ...
    if [ ! -d $USB_OPENVARIO ]; then
      error_stop "'$USB_OPENVARIO' don't exist!?!"
    fi
  fi 
fi

#------------------------------------------------------------------------------
# Selecting image file:
select_image

# Complete Update
if [ -f "${IMAGEFILE}" ]; then
    echo "Start..."
    # make tmp dir clean:
    if [ -d "$RECOVER_DIR" ]; then
        chmod 757 -R $RECOVER_DIR
        # don't delete, better to make 'with rsync --delete' rm -r $RECOVER_DIR
    fi

    if [ "$FW_TYPE_BASE" = "1" ]; then # Base is old, delete all nmea logs (log folder)
    # because this can be very big and destroy the upgrade...    
      rm -vfr $PARTITION2_ROOT/.xcsoar/logs
      rm -vfr $PARTITION2_ROOT/.xcsoar/cache
    fi

    # 1st: Save the system
    save_system

    # 2nd: move saving recovery data to ov-upgrade.itb
    
    # Better as copy is writing the name in the 'upgrade file'
    echo "Firmware ImageFile = $IMAGE_NAME !"
    echo "IMAGEFILE=$IMAGE_NAME" >> $UPGRADE_CFG
    echo "Upgrade step 1 finished!"

    # chmod 757 -R $MNT_DIR
    # rm -rf $MNT_DIR

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
    if [ -z "$IMAGEFILE" ]; then
        echo "IMAGEFILE is empty, no recovery!"
    else
        echo "'$IMAGE_NAME' don't exist, no recovery!"
    fi
fi
