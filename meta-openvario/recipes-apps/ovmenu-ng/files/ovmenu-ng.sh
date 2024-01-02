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

#### 17:52 TestStep  10
#### 17:52 main_menu() {
#### 17:52   echo "call main_menu" >> $DEBUG_LOG
#### 17:52     ### display main menu ###
#### 17:52     declare -a menu_array=()
#### 17:52     ## declare -a menu_array=("OpenSoar"      "Start OpenSoar")
#### 17:52     ## if [ "$MENU_VERSION" = "club" ]; then
#### 17:52     ##   menu_array+=("OpenSoarClub"  "Start OpenSoarClub")
#### 17:52     ## fi
#### 17:52     ## menu_array+=("XCSoar"        "Start XCSoar")
#### 17:52     ## menu_array+=("File Copy"     "Copys file to and from OpenVario")
#### 17:52     ## menu_array+=("System Menu"   "Update, Settings, ...")
#### 17:52     ## menu_array+=("Linux Shell"   "Exit to the shell")
#### 17:52     ## menu_array+=("Reboot"        "Reboot")
#### 17:52     ## menu_array+=("Power OFF"     "Shutdown and Power OFF")
#### 17:52     menu_array+=("Test OVM"          "Test with OpenVarioMenu")
#### 17:52 
#### 17:52     dialog --clear --nocancel --backtitle "OpenVario" \
#### 17:52     --title "[ M A I N - M E N U ]" \
#### 17:52     --begin 3 4 \
#### 17:52     --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
#### 17:52     "${menu_array[@]}" \
#### 17:52     2>"${INPUT}"
#### 17:52 
#### 17:52     menuitem=$(<"${INPUT}")
#### 17:52 
#### 17:52     # make decsion
#### 17:52     case $menuitem in
#### 17:52 ##         "OpenSoar")     start_opensoar;;
#### 17:52 ##         "OpenSoarClub") start_opensoar_club;;
#### 17:52 ##         "XCSoar")       start_xcsoar;;
#### 17:52 ##         "File Copy")    submenu_file;;
#### 17:52 ##         "System Menu")  submenu_system;;
#### 17:52 ##         "Linux Shell")  do_shell;;
#### 17:52 ##         "Reboot")       do_reboot;; 
#### 17:52 ##         "Power OFF")    do_power_off 3;;
#### 17:52         "Test OVM")     do_OVM;;
#### 17:52     esac
#### 17:52 }

##### 17:48main_menu() {
##### 17:48  echo "call main_menu" >> $DEBUG_LOG
##### 17:48    ### display main menu ###
##### 17:48    declare -a menu_array=("OpenSoar"      "Start OpenSoar")
##### 17:48    if [ "$MENU_VERSION" = "club" ]; then
##### 17:48      menu_array+=("OpenSoarClub"  "Start OpenSoarClub")
##### 17:48    fi
##### 17:48    menu_array+=("XCSoar"        "Start XCSoar")
##### 17:48    menu_array+=("File Copy"     "Copys file to and from OpenVario")
##### 17:48    menu_array+=("System Menu"   "Update, Settings, ...")
##### 17:48    menu_array+=("Linux Shell"   "Exit to the shell")
##### 17:48    menu_array+=("Reboot"        "Reboot")
##### 17:48    menu_array+=("Power OFF"     "Shutdown and Power OFF")
##### 17:48    menu_array+=("Test OVM"          "Test with OpenVarioMenu")
##### 17:48
##### 17:48    dialog --clear --nocancel --backtitle "OpenVario" \
##### 17:48    --title "[ M A I N - M E N U ]" \
##### 17:48    --begin 3 4 \
##### 17:48    --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
##### 17:48    "${menu_array[@]}" \
##### 17:48    2>"${INPUT}"
##### 17:48
##### 17:48    menuitem=$(<"${INPUT}")
##### 17:48
##### 17:48    # make decsion
##### 17:48    case $menuitem in
##### 17:48        "OpenSoar")     start_opensoar;;
##### 17:48        "OpenSoarClub") start_opensoar_club;;
##### 17:48        "XCSoar")       start_xcsoar;;
##### 17:48        "File Copy")    submenu_file;;
##### 17:48        "System Menu")  submenu_system;;
##### 17:48        "Linux Shell")  do_shell;;
##### 17:48        "Reboot")       do_reboot;; 
##### 17:48        "Power OFF")    do_power_off 3;;
##### 17:48        "Test OVM")     do_OVM;;
##### 17:48    esac
##### 17:48}
##### 17:48
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  13
##### 17:47 function submenu_file() {
##### 17:47 
##### 17:47   ### display file menu ###
##### 17:47   dialog --nocancel --backtitle "OpenVario" \
##### 17:47   --title "[ F I L E ]" \
##### 17:47   --begin 3 4 \
##### 17:47   --menu "You can use the UP/DOWN arrow keys" 15 50 4 \
##### 17:47   Download_IGC   "Download XCSoar IGC files to USB" \
##### 17:47   Download   "Download XCSoar to USB" \
##### 17:47   Upload   "Upload files from USB to XCSoar" \
##### 17:47   "Reset Data"   "Reset complete data files from USB" \
##### 17:47   Back   "Back to Main" 2>"${INPUT}"
##### 17:47 
##### 17:47   menuitem=$(<"${INPUT}")
##### 17:47   
##### 17:47   # make decsion
##### 17:47   case $menuitem in
##### 17:47       Download_IGC) download_igc_files;;
##### 17:47       Download) download_files;;
##### 17:47       Upload) upload_files;;
##### 17:47       "Reset Data") reset_data;;
##### 17:47       Exit) ;;
##### 17:47   esac
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  14
##### 17:47 function submenu_system() {
##### 17:47   ### display system menu ###
##### 17:47   dialog --nocancel --backtitle "OpenVario" \
##### 17:47   --title "[ S Y S T E M ]" \
##### 17:47   --begin 3 4 \
##### 17:47   --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
##### 17:47   "Upgrade FW"          "Update complete system firmware" \
##### 17:47   "Update Packg"        "Update system software" \
##### 17:47   "Save Image"          "Save current image.." \
##### 17:47   "Calibrate Sensors"   "Calibrate Sensors" \
##### 17:47   "Calibrate Touch"     "Calibrate Touch" \
##### 17:47   "Settings"            "System Settings" \
##### 17:47   "Information"         "System Info" \
##### 17:47   "Back"                "Back to Main" \
##### 17:47   2>"${INPUT}"
##### 17:47 
##### 17:47   menuitem=$(<"${INPUT}")
##### 17:47 
##### 17:47   # make decsion
##### 17:47   case $menuitem in
##### 17:47       "Upgrade FW")
##### 17:47           upgrade_firmware
##### 17:47           ;;
##### 17:47       "Update Packg")
##### 17:47           update_system
##### 17:47           ;;
##### 17:47       "Save Image")
##### 17:47           save_image
##### 17:47           ;;
##### 17:47       "Calibrate Sensors")
##### 17:47           calibrate_sensors
##### 17:47           ;;
##### 17:47       "Calibrate Touch")
##### 17:47           calibrate_touch
##### 17:47           ;;
##### 17:47       "Settings")
##### 17:47           submenu_settings
##### 17:47           ;;
##### 17:47       "Information")
##### 17:47           show_info
##### 17:47           ;;
##### 17:47       "Exit") ;;
##### 17:47   esac
##### 17:47 }
##### 17:47 
##### 17:47 TestStep  15
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 function show_info() {
##### 17:47     ### collect info of system and show them in a dialog 
##### 17:47 	/usr/bin/system-info.sh > /tmp/tail.$$ &
##### 17:47 	dialog --backtitle "OpenVario" --title "Result" \
##### 17:47            --tailbox /tmp/tail.$$ 30 50
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 function submenu_settings() {
##### 17:47     ### display settings menu ###
##### 17:47     dialog --nocancel --backtitle "OpenVario" \
##### 17:47     --title "[ S Y S T E M ]" \
##### 17:47     --begin 3 4 \
##### 17:47     --menu "You can use the UP/DOWN arrow keys" 15 50 5 \
##### 17:47     "Display Rotation"  "Set rotation of the display" \
##### 17:47     "LCD Brightness"    "Set display brightness" \
##### 17:47     "SSH"               "Enable or disable SSH" \
##### 17:47     "Back"              "Back to Main" \
##### 17:47     2>"${INPUT}"
##### 17:47 
##### 17:47     menuitem=$(<"${INPUT}")
##### 17:47 
##### 17:47     # make decsion
##### 17:47     case $menuitem in
##### 17:47         "Display Rotation")
##### 17:47             submenu_rotation
##### 17:47             ;;
##### 17:47         "LCD Brightness")
##### 17:47             submenu_lcd_brightness
##### 17:47             ;;
##### 17:47         "SSH")
##### 17:47             submenu_ssh
##### 17:47             ;;
##### 17:47         "Back") ;;
##### 17:47     esac
##### 17:47 }
##### 17:47 
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  16
##### 17:47 function submenu_ssh() {
##### 17:47     if /bin/systemctl --quiet is-enabled dropbear.socket; then
##### 17:47         local state=enabled
##### 17:47     elif /bin/systemctl --quiet is-active dropbear.socket; then
##### 17:47         local state=temporary
##### 17:47     else
##### 17:47         local state=disabled
##### 17:47     fi
##### 17:47 
##### 17:47     dialog --nocancel --backtitle "OpenVario" \
##### 17:47         --title "[ S S H ]" \
##### 17:47         --begin 3 4 \
##### 17:47         --default-item "${state}" \
##### 17:47         --menu "SSH access is currently ${state}." 15 50 4 \
##### 17:47         enabled     "Enable SSH permanently" \
##### 17:47         temporary   "Enable SSH temporarily (until reboot)" \
##### 17:47         disabled    "Disable SSH" \
##### 17:47         2>"${INPUT}"
##### 17:47     menuitem=$(<"${INPUT}")
##### 17:47 
##### 17:47     if test "${state}" != "$menuitem"; then
##### 17:47         if test "$menuitem" = "enabled"; then
##### 17:47             /bin/systemctl enable --now dropbear.socket
##### 17:47         elif test "$menuitem" = "temporary"; then
##### 17:47             /bin/systemctl disable dropbear.socket
##### 17:47             /bin/systemctl start dropbear.socket
##### 17:47         else
##### 17:47             /bin/systemctl disable --now dropbear.socket
##### 17:47         fi
##### 17:47     fi
##### 17:47   submenu_settings
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  17
##### 17:47 function submenu_lcd_brightness() {
##### 17:47   while [ $? -eq 0 ]
##### 17:47   do
##### 17:47       menuitem=$(</sys/class/backlight/lcd/brightness)
##### 17:47       dialog --backtitle "OpenVario" \
##### 17:47       --title "LCD brightness" \
##### 17:47       --cancel-label Back \
##### 17:47       --ok-label Set \
##### 17:47       --default-item "${menuitem}" \
##### 17:47       --menu "Brightness value" \
##### 17:47       17 50 10 \
##### 17:47       1 "Dark" \
##### 17:47       2 "" \
##### 17:47       3 "" \
##### 17:47       4 "" \
##### 17:47       5 "Medium" \
##### 17:47       6 "" \
##### 17:47       7 "" \
##### 17:47       8 "" \
##### 17:47       9 "" \
##### 17:47       10 "Bright" \
##### 17:47       2>/sys/class/backlight/lcd/brightness
##### 17:47   done
##### 17:47   new_value=$(</sys/class/backlight/lcd/brightness)
##### 17:47   if [ -z "$new_value" ]; then 
##### 17:47     # in case of ESC brightness is empty
##### 17:47     echo "$menuitem" > /sys/class/backlight/lcd/brightness
##### 17:47   else
##### 17:47     # for later usage (upgrade fw...)
##### 17:47     count=$(grep -c "brightness" /boot/config.uEnv)
##### 17:47     if [ "$count"´-eq "0" ]; then 
##### 17:47       echo "brightness=$new_value" >> /boot/config.uEnv
##### 17:47     else
##### 17:47       sed -i 's/^brightness=.*/brightness='$new_value'/' /boot/config.uEnv
##### 17:47     fi
##### 17:47     debug_stop "brightness = $new_value"
##### 17:47   fi
##### 17:47   
##### 17:47   submenu_settings
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  18
##### 17:47 function submenu_rotation() {
##### 17:47   temp=$(grep "rotation" /boot/config.uEnv)
##### 17:47   if [ -n temp ]; then
##### 17:47     rotation=${temp: -1}
##### 17:47     dialog --nocancel --backtitle "OpenVario" \
##### 17:47         --title "[ S Y S T E M ]" \
##### 17:47         --begin 3 4 \
##### 17:47         --default-item "${rotation}" \
##### 17:47         --menu "Select Rotation:" 15 50 4 \
##### 17:47          0 "Landscape 0 deg" \
##### 17:47          1 "Portrait 90 deg" \
##### 17:47          2 "Landscape 180 deg" \
##### 17:47          3 "Portrait 270 deg" 2>"${INPUT}"
##### 17:47     
##### 17:47     new_value=$(<"${INPUT}")
##### 17:47     if [ -z "$new_value" ]; then 
##### 17:47       echo "Rotation: Cancel or ESC!"
##### 17:47     elif [ "$new_value" = "$rotation" ]; then
##### 17:47       echo "Rotation value not changed = '$rotation'!"
##### 17:47     else
##### 17:47       echo "diff values: new_value = '$new_value', temp = '$temp', rotation = '$rotation'"
##### 17:47       # update config
##### 17:47       # uboot rotation
##### 17:47       sed -i 's/^rotation=.*/rotation='$new_value'/' /boot/config.uEnv
##### 17:47       echo "$new_value" >/sys/class/graphics/fbcon/rotate_all
##### 17:47       dialog --msgbox "New Setting saved !!\n Touch recalibration required !!" 10 50
##### 17:47     fi
##### 17:47   else
##### 17:47       dialog --backtitle "OpenVario" \
##### 17:47       --title "ERROR" \
##### 17:47       --msgbox "No Config found !!"
##### 17:47   fi
##### 17:47   submenu_settings
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  19
##### 17:47 function update_system() {
##### 17:47     echo "Updating System ..." > /tmp/tail.$$
##### 17:47     opkg update &>/dev/null
##### 17:47     OPKG_UPDATE=$(opkg list-upgradable)
##### 17:47 
##### 17:47     dialog --backtitle "Openvario" \
##### 17:47     --begin 3 4 \
##### 17:47     --defaultno \
##### 17:47     --title "Update" --yesno "$OPKG_UPDATE" 15 40
##### 17:47 
##### 17:47     response=$?
##### 17:47     case $response in
##### 17:47         0) opkg upgrade &>/tmp/tail.$$
##### 17:47         sync
##### 17:47         dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
##### 17:47         ;;
##### 17:47     esac
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  20
##### 17:47 function upgrade_firmware() {
##### 17:47     echo "Upgrade Firmware ..." > /tmp/tail.$$
##### 17:47     /usr/bin/fw-upgrade.sh
##### 17:47     echo "firmware upgrade interrupted..."
##### 17:47     echo "==============================="
##### 17:47     sync
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  21
##### 17:47 function calibrate_sensors() {
##### 17:47 
##### 17:47     dialog --backtitle "Openvario" \
##### 17:47     --begin 3 4 \
##### 17:47     --defaultno \
##### 17:47     --title "Sensor Calibration" --yesno "Really want to calibrate sensors ?? \n This takes a few moments ...." 10 40
##### 17:47 
##### 17:47     response=$?
##### 17:47     case $response in
##### 17:47         0) ;;
##### 17:47         *) return 0
##### 17:47     esac
##### 17:47 
##### 17:47     echo "Calibrating Sensors ..." >> /tmp/tail.$$
##### 17:47     systemctl stop variod.service sensord.socket 'sensord@*.service'
##### 17:47     /opt/bin/sensorcal -c > /tmp/tail.$$
##### 17:47 
##### 17:47     if [ $? -eq 2 ]
##### 17:47     then
##### 17:47         # board not initialised
##### 17:47         dialog --backtitle "Openvario" \
##### 17:47         --begin 3 4 \
##### 17:47         --defaultno \
##### 17:47         --title "Init Sensorboard" --yesno "Sensorboard is virgin ! \n Do you want to initialize ??" 10 40
##### 17:47 
##### 17:47         response=$?
##### 17:47         case $response in
##### 17:47             0) /opt/bin/sensorcal -i > /tmp/tail.$$
##### 17:47             ;;
##### 17:47         esac
##### 17:47         echo "Please run sensorcal again !!!" > /tmp/tail.$$
##### 17:47     fi
##### 17:47     sync
##### 17:47     dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
##### 17:47     systemctl restart variod.service
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  22
##### 17:47 function calibrate_touch() {
##### 17:47     echo "Calibrating Touch ..." >> /tmp/tail.$$
##### 17:47     /usr/bin/ov-calibrate-ts.sh >> /tmp/tail.$$
##### 17:47     dialog --msgbox "Calibration OK!" 10 50
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  23
##### 17:47 # Copy /home/root/data/OpenSoarData to $USB_OPENVARIO/download/OpenSoarData
##### 17:47 function download_files() {
##### 17:47     /usr/bin/transfers.sh download-data $main_app >> /tmp/tail.$$ &
##### 17:47     dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  24
##### 17:47 # Copy /home/root/OpenSoarData/logs to $USB_OPENVARIO/igc
##### 17:47 # Copy only *.igc files
##### 17:47 function download_igc_files() {
##### 17:47     /usr/bin/download-igc.sh
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  25
##### 17:47 # Copy $USB_OPENVARIO/upload to /home/root/data/OpenSoarData
##### 17:47 function upload_files() {
##### 17:47     /usr/bin/transfers.sh upload-data $main_app  >> /tmp/tail.$$ &
##### 17:47     dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
##### 17:47 
##### 17:47 #    /usr/bin/upload-opensoar.sh >> /tmp/tail.$$ &
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  26
##### 17:47 # Reset $USB_OPENVARIO/upload to /home/root/data/OpenSoarData
##### 17:47 function reset_data() {
##### 17:47     /usr/bin/transfers.sh sync-data $main_app >> /tmp/tail.$$ &
##### 17:47     dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
##### 17:47 }
##### 17:47 
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  27
##### 17:47 # datapath with short name: better visibility im OpenSoar/XCSoar
##### 17:47 function check_exit_code() {
##### 17:47   case "$1" in
##### 17:47     100) # 'eventExit' without unknown misc argument
##### 17:47       # do nothing
##### 17:47       echo "OpenSoar Exit Code: $1 = 100(simple end)"
##### 17:47     ;;
##### 17:47     139) # 'Quit' in StartScreen
##### 17:47       # do nothing
##### 17:47       echo "OpenSoar Exit Code: $1 = 139(simple end)"
##### 17:47     ;;
##### 17:47     200) # Quit
##### 17:47       # do nothing
##### 17:47       echo "OpenSoar Exit Code: $1 = 200(simple end)"
##### 17:47     ;;
##### 17:47     201) # Reboot
##### 17:47       do_reboot
##### 17:47     ;;
##### 17:47     202) # ShutDown
##### 17:47       do_power_off  5
##### 17:47     ;;
##### 17:47     203) # start Firmware Upgrade
##### 17:47       upgrade_firmware
##### 17:47     ;;
##### 17:47     *)
##### 17:47       echo "OpenSoar Exit Code: '$1'"
##### 17:47       read -p "Press enter to continue"
##### 17:47     ;;
##### 17:47   esac
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  28
##### 17:47 # datapath with short name: better visibility im OpenSoar/XCSoar
##### 17:47 function start_opensoar_club() {
##### 17:47     # reset the profile to standard profile
##### 17:47     CLUB_FILE=$DATADIR/.glider_club/GliderClub_Std.prf
##### 17:47     FLIGHT_FILE=$DATADIR/OpenSoarData/GliderClub.prf
##### 17:47     LAST_FILE=$(ls -rt1 $DATADIR/.glider_club/GliderClub_*.prf | tail -1)
##### 17:47     COMPARE1=$(cmp $CLUB_FILE $FLIGHT_FILE )
##### 17:47     COMPARE2=$(cmp $LAST_FILE $FLIGHT_FILE )
##### 17:47     if [ ! "$COMPARE1" = "" ] && [ ! "$COMPARE2" = "" ]; then
##### 17:47       # files differ...
##### 17:47       echo "Differ: '$COMPARE1' or '$COMPARE2'" >> $DEBUG_LOG
##### 17:47       if [ -e "$FLIGHT_FILE" ]; then
##### 17:47         DATE=$(date -r $DATADIR/OpenSoarData/GliderClub.prf "+%Y_%m_%d_%H%M")
##### 17:47         cp $FLIGHT_FILE   $DATADIR/.glider_club/GliderClub_$DATE.prf 
##### 17:47         echo "NewFile: GliderClub_$DATE.prf" >> $DEBUG_LOG
##### 17:47       fi 
##### 17:47       # read -p "Differ: '$COMPARE1'"
##### 17:47       cp $CLUB_FILE $FLIGHT_FILE
##### 17:47     fi
##### 17:47     # start the GliderClub version of opensoar
##### 17:47     /usr/bin/OpenSoar -fly -profile=data/OpenSoarData/GliderClub.prf \
##### 17:47       -datapath=data/OpenSoarData/
##### 17:47     check_exit_code $?
##### 17:47     sync
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  29
##### 17:47 function start_opensoar() {
##### 17:47     /usr/bin/OpenSoar -fly -datapath=data/OpenSoarData/
##### 17:47     check_exit_code $?
##### 17:47     sync
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  30
##### 17:47 function start_xcsoar() {
##### 17:47     /usr/bin/xcsoar -fly -datapath=data/XCSoarData/
##### 17:47     sync
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  31
##### 17:47 function do_reboot() {
##### 17:47     local REBOOT_TIMER=2
##### 17:47     if [ -n "$1" ]; then REBOOT_TIMER="$1"; fi
##### 17:47 
##### 17:47     dialog --backtitle "Openvario" \
##### 17:47     --title "Reboot ?" --pause \
##### 17:47     "Reboot OpenVario ... \\n Press [ESC] for interrupt" 10 30 $REBOOT_TIMER 2>&1
##### 17:47     RESULT=$?
##### 17:47     sync
##### 17:47     if [ "$RESULT" = "0" ]; then reboot; fi
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
##### 17:47 TestStep  32
##### 17:47 function do_power_off() {
##### 17:47     POWER_OFF_TIMER=4
##### 17:47     if [ -n "$1" ]; then POWER_OFF_TIMER="$1"; fi
##### 17:47 
##### 17:47     dialog --backtitle "Openvario" \
##### 17:47     --title "Power-OFF ?" --pause \
##### 17:47     "Really want to Power-OFF \\n Press [ESC] for interrupt" 10 30 $POWER_OFF_TIMER 2>&1
##### 17:47 
##### 17:47     RESULT=$?
##### 17:47     if [ "$RESULT" = "0" ]; then 
##### 17:47       sync
##### 17:47       shutdown -h now
##### 17:47     fi
##### 17:47 }
##### 17:47 
##### 17:47 #------------------------------------------------------------------------------
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

function do_OVM() {
   /usr/bin/OpenVarioMenu
   wait
   do_shell
   ## case $? in
   ##         0) do_shell;;
   ##       100) do_shell;;
   ##       200) do_reboot;; 
   ##       201) do_power_off 3;;
   ## esac
}
#==============================================================================
#==============================================================================
#==============================================================================
##### dialog --nook --nocancel --pause \
##### "Starting OpenSoar (!)... \\n Press [ESC] for menu" \
##### 10 30 $TIMEOUT 2>&1
##### 
##### case $? in
#####     0) 
#####       TestStep  36
#####       do_OVM
#####       # /usr/bin/OpenVarioMenu
#####       # $START_PROGRAM
#####     ;;
#####     *) 
#####        TestStep  37
#####        # /usr/bin/OpenVarioMenu
#####        main_menu
#####     ;;
##### esac
##### TestStep  38

while true
do
##  /usr/bin/OpenVarioMenu
##   main_menu
##   do_OVM
   /usr/bin/OpenVarioMenu
   wait
   do_shell
done

