#!/bin/bash

#Config
DEBUG_STOP="No"
VERBOSE="Yes"
WITH_TESTSTEPS="No"

TIMEOUT=0
INPUT=/tmp/menu.sh.$$
DIALOG_CANCEL=1
## HOME=/home/root
DATADIR=$HOME/data
USB_STICK=/usb/usbstick
USB_OPENVARIO=$USB_STICK/openvario
RECOVER_DIR=$HOME/recover_data

DEBUG_LOG=$HOME/start-debug.log
#------------------------------------------------------------------------------
function TestStep() {
  if [ "$WITH_TESTSTEPS" = "Yes" ]; then
    echo "Test step:  $1"
    echo "Test step:  $1"  >> $DEBUG_LOG
  fi
}
#------------------------------------------------------------------------------
function error_stop() {
    echo "Error-Stop: $1"
    read -p "Press enter to continue"
}

#------------------------------------------------------------------------------
function printv() {
    if [ "$VERBOSE" = "Yes" ]; then
      echo "$1"
      echo "$1" >> $DEBUG_LOG
    fi
}

#------------------------------------------------------------------------------
function debug_stop() {
    if [ "$DEBUG_STOP" = "Yes" ]; then
      echo "Debug-Stop: $1"
      read -p "Press enter to continue"
    fi
}

#------------------------------------------------------------------------------
function system_check() {
  printv "system_check"
  echo "System Check OpenVario"
  echo "======================"
  # in the beginning check the complete system
  # * check partition 2, should never filled about 400-450MB (if 468MB)
  # * check partition 3 how much free memory is available
  # * check if usb is in and check the size...
  # is there a possibility to create an event for insert and remove of the usb?
}

#=========================================================================
# a hidden possibility to change this file with a file from the USB-DIR
if [ -z "$1" ]; then
  if [ "$0" = "/usr/bin/ovmenu-ng.sh" ]; then
    echo "Call another ovmenu-ng.sh to change it 'on the fly'"
    if [ -f "$USB_OPENVARIO/ovmenu-ng.sh" ]; then 
      cp -vf "$USB_OPENVARIO/ovmenu-ng.sh" $HOME/
      chmod 757 $HOME/ovmenu-ng.sh
      echo "call '$HOME/ovmenu-ng.sh'"
      $HOME/ovmenu-ng.sh "New Start"
      echo "Extra ovmenu from '$USB_OPENVARIO'"
      exit
      debug_stop " exit after '$HOME/ovmenu-ng.sh'"
    fi
  fi
fi

#=========================================================================
#=========================================================================
#=========================================================================
echo "begin startup.."
echo "===============" 
chmod -Rf 757 $HOME
TestStep  PreStart
mv $HOME/start-debug-1.log $HOME/start-debug-2.log
mv $DEBUG_LOG $HOME/start-debug-1.log
TestStep  0
source /boot/config.uEnv
if [[ -z "$brightness" ]]; then 
  brightness=10
fi
echo "$brightness" >/sys/class/backlight/lcd/brightness
debug_stop "set brightness to '$brightness'"

# set system configs if upgrade.cfg is available (from Upgrade)
TestStep  0
cd $HOME
if [ -f $HOME/recover_data/upgrade.cfg ]; then
  echo "Update system config" > sysconfig.txt
  /usr/bin/update-system-config.sh
elif [ ! -f $HOME/recover_data/_upgrade.cfg ]; then
  echo "upgrade.cfg not found" > sysconfig.txt
else
  echo "only backup config found !!!!!" > sysconfig.txt
fi

echo "begin startup.. $(date %Y-%m-%d %H:%M:%S)" >> $DEBUG_LOG
DATESTRING=$(date %Y-%m-%d %H:%M:%S)
date %Y-%m-%d %H:%M:%S >> $DEBUG_LOG
TestStep  1
echo "=================================" >> $DEBUG_LOG
if [ ! -e /dev/mmcblk0p3 ]; then
  echo "/dev/mmcblk0p3 don't exist " >> $DEBUG_LOG
  ls -l /dev/mm* >> $DEBUG_LOG
  # create the 3rd SD card partition:
  source /usr/bin/create_datapart.sh

  echo "Debug: 3rd SD card partition created" >> $DEBUG_LOG
  if [ -f $HOME/_upgrade.cfg ]; then
    # reactivate the previous system data
    mv -f $HOME/_upgrade.cfg $HOME/upgrade.cfg
  fi 
      ### read -p "Press enter to continue"
  if [ ! -e /dev/mmcblk0p3 ]; then
    echo "Reboot ====================================" >> $DEBUG_LOG
    echo "Wait until OpenVario after Reboot is ready!" >> $DEBUG_LOG
    reboot
    ### read -p "Press enter to continue"
  fi
fi

TestStep  2
# Mount the 3rd partition to the data dir
# if [ ! -d $DATADIR ]; then mkdir $DATADIR; fi
mount /dev/mmcblk0p3 $DATADIR
if [ ! -d $DATADIR/OpenSoarData ]; then
  if ! mount /dev/mmcblk0p3 $DATADIR; then
    if ! mkfs.ext4 /dev/mmcblk0p3; then
      echo "Error 1: mmcblk0p3 couldn't be formatted"  >> $DEBUG_LOG
    fi
    if ! mount /dev/mmcblk0p3 $DATADIR; then
      echo "Error 2: mmcblk0p3 couldn't be mounted"  >> $DEBUG_LOG
    fi
  fi
else
  echo "mmcblk0p3 is mounted at '$DATADIR'"  >> $DEBUG_LOG
fi

TestStep  5
if [ -e $DATADIR/.glider_club/GliderClub_Std.prf ]; then
  MENU_VERSION="club"
else
  MENU_VERSION="normal"
fi

TestStep "6 - 'main_app'"
# detect main application and start this
export MAIN_APP=$main_app
case "$main_app" in 
  xcsoar)
      START_PROGRAM="start_xcsoar"
      ;;
  OpenSoar|*)
    if [ "$MENU_VERSION" = "club" ]; then
      START_PROGRAM="start_opensoar_club"
    else
      START_PROGRAM="start_opensoar"
    fi
    ;;
esac
  # LK8000)  START_PROGRAM="start_lk8000";;

TestStep "7 - 'START_PROGRAM'"

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

TestStep  10
main_menu() {
  echo "call main_menu" >> $DEBUG_LOG
    ### display main menu ###
    declare -a menu_array=("OpenSoar"      "Start OpenSoar")
    if [ "$MENU_VERSION" = "club" ]; then
      menu_array+=("OpenSoarClub"  "Start OpenSoarClub")
    fi
    menu_array+=("XCSoar"        "Start XCSoar")
    menu_array+=("File Copy"     "Copys file to and from OpenVario")
    menu_array+=("System Menu"   "Update, Settings, ...")
    menu_array+=("Linux Shell"   "Exit to the shell")
    menu_array+=("Reboot"        "Reboot")
    menu_array+=("Power OFF"     "Shutdown and Power OFF")
    menu_array+=("Test OVM"          "Test with OpenVarioMenu")

    dialog --clear --nocancel --backtitle "OpenVario" \
    --title "[ M A I N - M E N U ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
    "${menu_array[@]}" \
    2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        "OpenSoar")     start_opensoar;;
        "OpenSoarClub") start_opensoar_club;;
        "XCSoar")       start_xcsoar;;
        "File Copy")    submenu_file;;
        "System Menu")  submenu_system;;
        "Linux Shell")  do_shell;;
        "Reboot")       do_reboot;; 
        "Power OFF")    do_power_off 3;;
        "Test OVM")     /usr/bin/OpenVarioMenu;;
    esac
}

#------------------------------------------------------------------------------
TestStep  13
function submenu_file() {

  ### display file menu ###
  dialog --nocancel --backtitle "OpenVario" \
  --title "[ F I L E ]" \
  --begin 3 4 \
  --menu "You can use the UP/DOWN arrow keys" 15 50 4 \
  Download_IGC   "Download XCSoar IGC files to USB" \
  Download   "Download XCSoar to USB" \
  Upload   "Upload files from USB to XCSoar" \
  "Reset Data"   "Reset complete data files from USB" \
  Back   "Back to Main" 2>"${INPUT}"

  menuitem=$(<"${INPUT}")
  
  # make decsion
  case $menuitem in
      Download_IGC) download_igc_files;;
      Download) download_files;;
      Upload) upload_files;;
      "Reset Data") reset_data;;
      Exit) ;;
  esac
}

#------------------------------------------------------------------------------
TestStep  14
function submenu_system() {
  ### display system menu ###
  dialog --nocancel --backtitle "OpenVario" \
  --title "[ S Y S T E M ]" \
  --begin 3 4 \
  --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
  "Upgrade FW"          "Update complete system firmware" \
  "Update Packg"        "Update system software" \
  "Save Image"          "Save current image.." \
  "Calibrate Sensors"   "Calibrate Sensors" \
  "Calibrate Touch"     "Calibrate Touch" \
  "Settings"            "System Settings" \
  "Information"         "System Info" \
  "Back"                "Back to Main" \
  2>"${INPUT}"

  menuitem=$(<"${INPUT}")

  # make decsion
  case $menuitem in
      "Upgrade FW")
          upgrade_firmware
          ;;
      "Update Packg")
          update_system
          ;;
      "Save Image")
          save_image
          ;;
      "Calibrate Sensors")
          calibrate_sensors
          ;;
      "Calibrate Touch")
          calibrate_touch
          ;;
      "Settings")
          submenu_settings
          ;;
      "Information")
          show_info
          ;;
      "Exit") ;;
  esac
}

TestStep  15
#------------------------------------------------------------------------------
function show_info() {
    ### collect info of system and show them in a dialog 
	/usr/bin/system-info.sh > /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" \
           --tailbox /tmp/tail.$$ 30 50
}

#------------------------------------------------------------------------------
function submenu_settings() {
    ### display settings menu ###
    dialog --nocancel --backtitle "OpenVario" \
    --title "[ S Y S T E M ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 5 \
    "Display Rotation"  "Set rotation of the display" \
    "LCD Brightness"    "Set display brightness" \
    "SSH"               "Enable or disable SSH" \
    "Back"              "Back to Main" \
    2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        "Display Rotation")
            submenu_rotation
            ;;
        "LCD Brightness")
            submenu_lcd_brightness
            ;;
        "SSH")
            submenu_ssh
            ;;
        "Back") ;;
    esac
}


#------------------------------------------------------------------------------
TestStep  16
function submenu_ssh() {
    if /bin/systemctl --quiet is-enabled dropbear.socket; then
        local state=enabled
    elif /bin/systemctl --quiet is-active dropbear.socket; then
        local state=temporary
    else
        local state=disabled
    fi

    dialog --nocancel --backtitle "OpenVario" \
        --title "[ S S H ]" \
        --begin 3 4 \
        --default-item "${state}" \
        --menu "SSH access is currently ${state}." 15 50 4 \
        enabled     "Enable SSH permanently" \
        temporary   "Enable SSH temporarily (until reboot)" \
        disabled    "Disable SSH" \
        2>"${INPUT}"
    menuitem=$(<"${INPUT}")

    if test "${state}" != "$menuitem"; then
        if test "$menuitem" = "enabled"; then
            /bin/systemctl enable --now dropbear.socket
        elif test "$menuitem" = "temporary"; then
            /bin/systemctl disable dropbear.socket
            /bin/systemctl start dropbear.socket
        else
            /bin/systemctl disable --now dropbear.socket
        fi
    fi
  submenu_settings
}

#------------------------------------------------------------------------------
TestStep  17
function submenu_lcd_brightness() {
  while [ $? -eq 0 ]
  do
      menuitem=$(</sys/class/backlight/lcd/brightness)
      dialog --backtitle "OpenVario" \
      --title "LCD brightness" \
      --cancel-label Back \
      --ok-label Set \
      --default-item "${menuitem}" \
      --menu "Brightness value" \
      17 50 10 \
      1 "Dark" \
      2 "" \
      3 "" \
      4 "" \
      5 "Medium" \
      6 "" \
      7 "" \
      8 "" \
      9 "" \
      10 "Bright" \
      2>/sys/class/backlight/lcd/brightness
  done
  new_value=$(</sys/class/backlight/lcd/brightness)
  if [ -z "$new_value" ]; then 
    # in case of ESC brightness is empty
    echo "$menuitem" > /sys/class/backlight/lcd/brightness
  else
    # for later usage (upgrade fw...)
    count=$(grep -c "brightness" /boot/config.uEnv)
    if [ "$count"´-eq "0" ]; then 
      echo "brightness=$new_value" >> /boot/config.uEnv
    else
      sed -i 's/^brightness=.*/brightness='$new_value'/' /boot/config.uEnv
    fi
    debug_stop "brightness = $new_value"
  fi
  
  submenu_settings
}

#------------------------------------------------------------------------------
TestStep  18
function submenu_rotation() {
  temp=$(grep "rotation" /boot/config.uEnv)
  if [ -n temp ]; then
    rotation=${temp: -1}
    dialog --nocancel --backtitle "OpenVario" \
        --title "[ S Y S T E M ]" \
        --begin 3 4 \
        --default-item "${rotation}" \
        --menu "Select Rotation:" 15 50 4 \
         0 "Landscape 0 deg" \
         1 "Portrait 90 deg" \
         2 "Landscape 180 deg" \
         3 "Portrait 270 deg" 2>"${INPUT}"
    
    new_value=$(<"${INPUT}")
    if [ -z "$new_value" ]; then 
      echo "Rotation: Cancel or ESC!"
    elif [ "$new_value" = "$rotation" ]; then
      echo "Rotation value not changed = '$rotation'!"
    else
      echo "diff values: new_value = '$new_value', temp = '$temp', rotation = '$rotation'"
      # update config
      # uboot rotation
      sed -i 's/^rotation=.*/rotation='$new_value'/' /boot/config.uEnv
      echo "$new_value" >/sys/class/graphics/fbcon/rotate_all
      dialog --msgbox "New Setting saved !!\n Touch recalibration required !!" 10 50
    fi
  else
      dialog --backtitle "OpenVario" \
      --title "ERROR" \
      --msgbox "No Config found !!"
  fi
  submenu_settings
}

#------------------------------------------------------------------------------
TestStep  19
function update_system() {
    echo "Updating System ..." > /tmp/tail.$$
    opkg update &>/dev/null
    OPKG_UPDATE=$(opkg list-upgradable)

    dialog --backtitle "Openvario" \
    --begin 3 4 \
    --defaultno \
    --title "Update" --yesno "$OPKG_UPDATE" 15 40

    response=$?
    case $response in
        0) opkg upgrade &>/tmp/tail.$$
        sync
        dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
        ;;
    esac
}

#------------------------------------------------------------------------------
TestStep  20
function upgrade_firmware() {
    echo "Upgrade Firmware ..." > /tmp/tail.$$
    /usr/bin/fw-upgrade.sh
    echo "firmware upgrade interrupted..."
    echo "==============================="
    sync
}

#------------------------------------------------------------------------------
TestStep  21
function calibrate_sensors() {

    dialog --backtitle "Openvario" \
    --begin 3 4 \
    --defaultno \
    --title "Sensor Calibration" --yesno "Really want to calibrate sensors ?? \n This takes a few moments ...." 10 40

    response=$?
    case $response in
        0) ;;
        *) return 0
    esac

    echo "Calibrating Sensors ..." >> /tmp/tail.$$
    systemctl stop variod.service sensord.socket 'sensord@*.service'
    /opt/bin/sensorcal -c > /tmp/tail.$$

    if [ $? -eq 2 ]
    then
        # board not initialised
        dialog --backtitle "Openvario" \
        --begin 3 4 \
        --defaultno \
        --title "Init Sensorboard" --yesno "Sensorboard is virgin ! \n Do you want to initialize ??" 10 40

        response=$?
        case $response in
            0) /opt/bin/sensorcal -i > /tmp/tail.$$
            ;;
        esac
        echo "Please run sensorcal again !!!" > /tmp/tail.$$
    fi
    sync
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
    systemctl restart variod.service
}

#------------------------------------------------------------------------------
TestStep  22
function calibrate_touch() {
    echo "Calibrating Touch ..." >> /tmp/tail.$$
    /usr/bin/ov-calibrate-ts.sh >> /tmp/tail.$$
    dialog --msgbox "Calibration OK!" 10 50
}

#------------------------------------------------------------------------------
TestStep  23
# Copy /home/root/data/OpenSoarData to $USB_OPENVARIO/download/OpenSoarData
function download_files() {
    /usr/bin/transfers.sh download-data $main_app >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

#------------------------------------------------------------------------------
TestStep  24
# Copy /home/root/OpenSoarData/logs to $USB_OPENVARIO/igc
# Copy only *.igc files
function download_igc_files() {
    /usr/bin/download-igc.sh
}

#------------------------------------------------------------------------------
TestStep  25
# Copy $USB_OPENVARIO/upload to /home/root/data/OpenSoarData
function upload_files() {
    /usr/bin/transfers.sh upload-data $main_app  >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50

#    /usr/bin/upload-opensoar.sh >> /tmp/tail.$$ &
}

#------------------------------------------------------------------------------
TestStep  26
# Reset $USB_OPENVARIO/upload to /home/root/data/OpenSoarData
function reset_data() {
    /usr/bin/transfers.sh sync-data $main_app >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}


#------------------------------------------------------------------------------
TestStep  27
# datapath with short name: better visibility im OpenSoar/XCSoar
function check_exit_code() {
  case "$1" in
    100) # 'eventExit' without unknown misc argument
      # do nothing
      echo "OpenSoar Exit Code: $1 = 100(simple end)"
    ;;
    139) # 'Quit' in StartScreen
      # do nothing
      echo "OpenSoar Exit Code: $1 = 139(simple end)"
    ;;
    200) # Quit
      # do nothing
      echo "OpenSoar Exit Code: $1 = 200(simple end)"
    ;;
    201) # Reboot
      do_reboot
    ;;
    202) # ShutDown
      do_power_off  5
    ;;
    203) # start Firmware Upgrade
      upgrade_firmware
    ;;
    *)
      echo "OpenSoar Exit Code: '$1'"
      read -p "Press enter to continue"
    ;;
  esac
}

#------------------------------------------------------------------------------
TestStep  28
# datapath with short name: better visibility im OpenSoar/XCSoar
function start_opensoar_club() {
    # reset the profile to standard profile
    CLUB_FILE=$DATADIR/.glider_club/GliderClub_Std.prf
    FLIGHT_FILE=$DATADIR/OpenSoarData/GliderClub.prf
    LAST_FILE=$(ls -rt1 $DATADIR/.glider_club/GliderClub_*.prf | tail -1)
    COMPARE1=$(cmp $CLUB_FILE $FLIGHT_FILE )
    COMPARE2=$(cmp $LAST_FILE $FLIGHT_FILE )
    if [ ! "$COMPARE1" = "" ] && [ ! "$COMPARE2" = "" ]; then
      # files differ...
      echo "Differ: '$COMPARE1' or '$COMPARE2'" >> $DEBUG_LOG
      if [ -e "$FLIGHT_FILE" ]; then
        DATE=$(date -r $DATADIR/OpenSoarData/GliderClub.prf "+%Y_%m_%d_%H%M")
        cp $FLIGHT_FILE   $DATADIR/.glider_club/GliderClub_$DATE.prf 
        echo "NewFile: GliderClub_$DATE.prf" >> $DEBUG_LOG
      fi 
      # read -p "Differ: '$COMPARE1'"
      cp $CLUB_FILE $FLIGHT_FILE
    fi
    # start the GliderClub version of opensoar
    /usr/bin/OpenSoar -fly -profile=data/OpenSoarData/GliderClub.prf \
      -datapath=data/OpenSoarData/
    check_exit_code $?
    sync
}

#------------------------------------------------------------------------------
TestStep  29
function start_opensoar() {
    /usr/bin/OpenSoar -fly -datapath=data/OpenSoarData/
    check_exit_code $?
    sync
}

#------------------------------------------------------------------------------
TestStep  30
function start_xcsoar() {
    /usr/bin/xcsoar -fly -datapath=data/XCSoarData/
    sync
}

#------------------------------------------------------------------------------
TestStep  31
function do_reboot() {
    local REBOOT_TIMER=2
    if [ -n "$1" ]; then REBOOT_TIMER="$1"; fi

    dialog --backtitle "Openvario" \
    --title "Reboot ?" --pause \
    "Reboot OpenVario ... \\n Press [ESC] for interrupt" 10 30 $REBOOT_TIMER 2>&1
    RESULT=$?
    sync
    if [ "$RESULT" = "0" ]; then reboot; fi
}

#------------------------------------------------------------------------------
TestStep  32
function do_power_off() {
    POWER_OFF_TIMER=4
    if [ -n "$1" ]; then POWER_OFF_TIMER="$1"; fi

    dialog --backtitle "Openvario" \
    --title "Power-OFF ?" --pause \
    "Really want to Power-OFF \\n Press [ESC] for interrupt" 10 30 $POWER_OFF_TIMER 2>&1

    RESULT=$?
    if [ "$RESULT" = "0" ]; then 
      sync
      shutdown -h now
    fi
}

#------------------------------------------------------------------------------
TestStep  34
function do_shell() {
    clear
    cd

    # Redirecting stderr to stdout (= the console)
    # because stderr is currently connected to
    # systemd-journald, which breaks interactive
    # shells.
    if test -x /bin/bash; then
        /bin/bash --login 2>&1
    elif test -x /bin/ash; then
        /bin/ash -i 2>&1
    else
        /bin/sh 2>&1
    fi
}

#==============================================================================
#==============================================================================
#==============================================================================
dialog --nook --nocancel --pause \
"Starting OpenSoar (!)... \\n Press [ESC] for menu" \
10 30 $TIMEOUT 2>&1

case $? in
    0) 
      TestStep  36
      /usr/bin/OpenVarioMenu
      # $START_PROGRAM
    ;;
    *) 
       TestStep  37
       # /usr/bin/OpenVarioMenu
       main_menu
    ;;
esac
TestStep  38

while true
do
##  /usr/bin/OpenVarioMenu
##  case $? in
##          0) do_shell;;
##        100) do_shell;;
##        200) do_reboot;; 
##        201) do_power_off 3;;
##  esac
  ## main_menu
done

