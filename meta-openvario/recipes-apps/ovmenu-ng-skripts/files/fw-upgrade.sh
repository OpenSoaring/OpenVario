#!/bin/bash

echo "Firmware Upgrade OpenVario"
echo "=========================="

DEBUG_STOP="n"

USB_STICK=/usb/usbstick

if [ ! -d "$USB_STICK" ]; then
  # this could be at 17119 FW..
  USB_STICK=/usb
fi
echo "USB stick will be mounted on '$USB_STICK'"

stat

DIALOG_CANCEL=1
SELECTION=/tmp/output.sh.$$

# the OV dirname at USB stick
OV_DIRNAME=$USB_STICK/openvario

# timestamp > OV-3.0.1-19-CB2-XXXX.img.gz
# timestamp > OV-3.0.1-19-CB2-XXXX.img.gz
TIMESTAMP_3_19=1695000000

# temporary directories at USB stick to save the setting informations
SDC_DIR=$OV_DIRNAME/recover_data
MNT_DIR="mnt"
# MNT_DIR=$OV_DIRNAME/usb

# SD card:
TARGET=/dev/mmcblk0
IMAGEFILE=""
TARGET_HW="0000"
TARGET_FILENAME_TYPE=0
TARGET_FW_VERSION=0
BASE_HW="0000"
BASE_FW_VERSION=0

# partition 1 of SD card is mounted as '/boot'!
PART1=/boot
# partition 2 of SD card is mounted on the root of the system
PART2_ROOT=/home/root
# partition 3 of SD card is mounted on the root of the system
PART3=$PART2_ROOT/data

rsync --version > /dev/null
if [ "$?" -eq "0" ]; then
   RSYNC_COPY="ok"
fi

#------------------------------------------------------------------------------
BATCH_PATH=$(dirname $0)
echo "Batch Path = '$BATCH_PATH'"
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
vercomp () {
    echo "compare '$1' vs. '$2'"
    echo "---------------------"
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
    # images=$OV_DIRNAME/images/O*V*-*.gz
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
    images=$OV_DIRNAME/images/O*V*-*.gz
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
            # TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
            TARGET_FW_VERSION=$(echo $IMAGE_NAME | grep -oE '[0-9]+[.][0-9]+[.][0-9]+')
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
        echo "TARGET_HW:                '$TARGET_HW'"
        echo "TARGET_FILENAME_TYPE:     '$TARGET_FILENAME_TYPE'"
        debug_stop
    fi
}


#------------------------------------------------------------------------------
function clear_display(){
    #================== clear display (after diolog) =======================================================
    for ((i=1 ; i<=20 ; i++ )); do 
        echo ""
    done
}
    
#------------------------------------------------------------------------------
function save_system(){
    #================== System Config =======================================================
    echo "1st: save system config in config.uSys for restoring reason"
    # 1st save system config in config.uSys for restoring reason
      if [ "UPGRADE_TYPE" = "1" ]; then  # only from new to new...
        SDC_DIR=data/recover_data
      else
        if [ -d "$USB_STICK/openvario" ]; then  # indicats if USB stick is in and mounted
          SDC_DIR=$USB_STICK/openvario/recover_data
        fi    
      fi
    debug_stop "SDC_DIR  = $SDC_DIR"
    mkdir -p $SDC_DIR
    
    # start with a new 'config.uSys':
    rm -f $SDC_DIR/config.uSys
    if [ -f /lib/systemd/system-preset/50-disable_dropbear.preset ]; then
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

    tar cvf - /var/lib/connman | gzip >$SDC_DIR/connman.tar.gz

    brightness=$(</sys/class/backlight/lcd/brightness)
    if [ -n brightness ]; then
      echo "BRIGHTNESS=\"$brightness\""
      echo "BRIGHTNESS=\"$brightness\"" >> $SDC_DIR/config.uSys
    else
      echo "'brightness' doesn't exist"
      echo "BRIGHTNESS=\"9\"" >> $SDC_DIR/config.uSys    
    fi 
    
    # if config.uEnv not exist
    if [ ! -f $PART1/config.uEnv ]; then
        PART1="/mnt/boot"
        mkdir -p $PART1
        # $TARGET  = /dev/mmcblk0
        mount /dev/mmcblk0p1 $PART1
        if [ ! -f $PART1/config.uEnv ]; then
           error_stop "'$PART1/config.uEnv' don't exist!?!"
        fi
    fi
    source $PART1/config.uEnv
    # read 1st line in 'image-version-info'
    VERSION_INFO=$(head -n 1 $PART1/image-version-info)
    # fdtfile=openvario-57-lvds.dtb
    if [ -z "$fdtfile" ]; then
      # this means, we have a (very) old version (< 21000 ?)
      echo "'$fdtfile' don't exist!?!"
      echo "What is to do???"
      # VERSION_INFO=$(head -n 1 $PART1/image-version-info)
      fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $3}')
      if [ -z "$fdtfile" ]; then fdtfile=$(echo $VERSION_INFO | awk -F'-openvario-|-testing' '{print $2}'); fi
      fdtfile=$(echo $fdtfile | awk -F'-201|202' '{print $1}')
      fdtfile="openvario-$fdtfile"
      BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]{5}')
      debug_stop "fdtfile = '$fdtfile'!!!!"
    else
      # BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]+[.][0-9]+[.][0-9]+[-][0-9]+')
      BASE_FW_VERSION=$(echo $VERSION_INFO | grep -oE '[0-9]+[.][0-9]+[.][0-9]+')
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
        echo "BASE_HW:                '$BASE_HW'"
        debug_stop
    echo "HARDWARE=\"$BASE_HW\"" >> $SDC_DIR/config.uSys
    
    # 0 - equal, 1 - lower, 2 greater
    echo "1) '$BASE_FW_VERSION' => '$TARGET_FW_VERSION'"
    vercomp "${TARGET_FW_VERSION//-/.}" "3.2.19"
    TARGET_FW_TYPE=$?
    vercomp   "${BASE_FW_VERSION//-/.}"   "3.2.19"
    BASE_FW_TYPE=$?

    echo "2) '$BASE_FW_TYPE' => '$TARGET_FW_TYPE'"
    if [ "$TARGET_FW_TYPE" = "2" ]; then
      if [ "$BASE_FW_TYPE" = "2" ]; then
        UPGRADE_TYPE=1  # 1- from new fw to new fw
      else
        UPGRADE_TYPE=2  # 2 - from old fw to new fw
      fi
    else
      if [ "$BASE_FW_TYPE" = "2" ]; then
        UPGRADE_TYPE=3 # 3 - from new fw to old fw
      else
        UPGRADE_TYPE=4 # 4 - from old fw to old fw
      fi
    fi
    debug_stop "3) '$BASE_FW_TYPE' => '$TARGET_FW_TYPE' = UPGRADE_TYPE '$UPGRADE_TYPE'"

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
    echo "ROTATION=\"$rotation\"" >> $SDC_DIR/config.uSys

    # UpgradeType:
    # 1- from new fw to new fw
    # 2 - from old fw to new fw
    # 3 - from new fw to old fw
    # 4 - from old fw to old fw
    # other types are not supported (f.e. old to previous an so on)!
    echo "UPGRADE_TYPE=\"$UPGRADE_TYPE\"" >> $SDC_DIR/config.uSys
    echo "BASE_FW_TYPE=\"$BASE_FW_TYPE\"" >> $SDC_DIR/config.uSys
    echo "TARGET_FW_TYPE=\"$TARGET_FW_TYPE\"" >> $SDC_DIR/config.uSys
    echo "System Save End"
}

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
      ITB_TARGET=$OV_DIRNAME/ov-recovery.itb
      ### ITB_TARGET=./ov-recovery.itb
      if [ -f "$OV_DIRNAME/images/$TARGET_HW/ov-recovery.itb" ]; then
        # hardlink from FAT (USB-Stick..) is not possible 
        echo "copy 'ov-recovery.itb' in the correct directory..."
        cp -fv $OV_DIRNAME/images/$TARGET_HW/ov-recovery.itb   $ITB_TARGET
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
        boot_sector_file=$OV_DIRNAME/images/$TARGET_HW/bootsector.bin.gz
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


# check if usb dir exist and is mounted!
if [ ! -d $USB_STICK ]; then
  USB_STICK=/mnt/usb
  mkdir -p $USB_STICK
  mount /dev/sda1 $USB_STICK
  # or sdb1, sdc1, ...
  if [ ! -d $OV_DIRNAME ]; then
    error_stop "'$OV_DIRNAME' don't exist!?!"
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
    
    if [ ! -f $PART1/config.uEnv ]; then
      # sd partition 1 is not in boot gemounted...
      PART1="/mnt/sd1"
      mkdir -p $PART1
      
    fi

    # 1st: Save the system
    save_system


    # 2nd: save boot folder to Backup from partition 1
    echo "2nd: save boot folder to Backup from partition 1"
    # -d is invalid option? rm -fr $SDC_DIR/part1
    rm -fr $SDC_DIR/part1
    mkdir -p $SDC_DIR/part1
    echo "  copy command ..."
    # cp is available on all (old) firmware
    # copy only files from interest (no picture, no uImage) 
    cp -fv  $PART1/config.uEnv        $SDC_DIR/part1/
    cp -fv  $PART1/image-version-info $SDC_DIR/part1/
    # 17119 don't have a *.dtb file...
    # cp -fv  $PART1/*.dtb              $SDC_DIR/part1/

    # 3rd: save OpenSoarData/XCSoarData from partition 2 (or 3):
    echo "3rd: save OpenSoarData / XCSoarData from partition 2 or 3"
    if [ "$BASE_FW_TYPE" = "2" ]; then # Base is new, data on 3rd partition 
      # new firmware, rsync is available       
      # no rm, because synchronizing
      # with "$TARGET_FW_TYPE" = "2" this isn't necessary - but helps to find data
      mkdir -p $SDC_DIR/part2/OpenSoarData
      rsync -ruvtcE --progress $PART3/OpenSoarData/* $SDC_DIR/part2/OpenSoarData/ \
            --delete --exclude cache  --exclude logs
      rsync -ruvtcE --progress $PART3/XCSoarData/* $SDC_DIR/part2/XCSoarData/ \
            --delete --exclude cache  --exclude logs
      rsync -uvtcE --progress $PART2_ROOT/.bash_history $SDC_DIR/part2/
    else  # Base is old, data coming from '.xcsoar' folder
      if [ -n "$RSYNC_COPY" ]; then
          # no rm, because synchronizing
          mkdir -p $SDC_DIR/part2/xcsoar
          rsync -ruvtcE --progress $PART2_ROOT/.xcsoar/* $SDC_DIR/part2/xcsoar/ \
                --delete --exclude cache  --exclude logs
          rsync -uvtcE --progress $PART2_ROOT/.bash_history $SDC_DIR/part2/
      else
          echo "  copy command (rsync not available)..."
          # this is possible on older fw (17119 for example)
          rm -fr $SDC_DIR/part2/*
          mkdir -p $SDC_DIR/part2/xcsoar
          cp -rfv  $PART2_ROOT/.xcsoar/* $SDC_DIR/part2/xcsoar/
          cp -fv   $PART2_ROOT/.bash_history $SDC_DIR/part2/
      fi
    fi
    debug_stop

    # HardLink at FAT isn't possible
    if [ -d "$PART2_ROOT/.glider_club" ]; then
        echo "save gliderclub data from partition 2"
        mkdir -p $SDC_DIR/part2/glider_club
        cp -frv $PART2_ROOT/.glider_club/* $SDC_DIR/part2/glider_club/
    fi
    
    # Synchronize the commands (?)
    sync

    # Better as copy is writing the name in the 'upgrade file'
    echo "Firmware ImageFile = $IMAGE_NAME !"
    if [ "$BASE_FW_TYPE" = "2" ]; then
      echo "$IMAGE_NAME" > data/upgrade.file
    else
      echo "$IMAGE_NAME" > $OV_DIRNAME/upgrade.file
    fi

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
