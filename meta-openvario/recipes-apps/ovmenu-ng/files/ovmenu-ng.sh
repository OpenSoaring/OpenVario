#!/bin/bash

#Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$
DIALOG_CANCEL=1
HOMEDIR=/home/root
DATADIR=$HOMEDIR/data

if [ ! -e /dev/mmcblk0p3 ]; then
  # create the 3rd SD card partition:
  source /usr/bin/create_datapart.sh

  echo "Debug-Stop: 3rd SD card partition created"
  if [ -f $HOMEDIR/_config.uSys ]; then
    # reactivate the previous system data
    mv -f $HOMEDIR/_config.uSys $HOMEDIR/config.uSys
  fi 
      ### read -p "Press enter to continue"
  if [ ! -e /dev/mmcblk0p3 ]; then
    echo "Reboot ===================================="
    echo "Wait until OpenVario after Reboot is ready!"
    reboot
    read -p "Press enter to continue"
  fi
fi

# Mount the 3rd partition to the data dir
# if [ ! -d $DATADIR ]; then mkdir $DATADIR; fi
if ! mount /dev/mmcblk0p3 $DATADIR; then
  if ! mkfs.ext4 -L "ov-data" /dev/mmcblk0p3; then
    echo "Error 1: mmcblk0p3 couldn't be formatted"
  fi
  if ! mount /dev/mmcblk0p3 $DATADIR; then
    echo "Error 2: mmcblk0p3 couldn't be mounted"
  fi
fi


if [ ! -d $DATADIR/XCSoarData ]; then
  # the data dir is new and has to be filled
  mkdir -p $DATADIR/XCSoarData
  echo "'data/XCSoarData'is new and has to be filled..."
  mv -v $HOMEDIR/.xcsoar/* $DATADIR/XCSoarData
  rm -f $HOMEDIR/.xcsoar
fi

if [ -e ~/.glider_club/GliderClub_Std.prf ]; then
  MENU_VERSION="club"
  MENU_ITEM="club_menu"
  START_PROGRAM="start_opensoar_club"
else
  MENU_VERSION="normal"
  MENU_ITEM="normal_menu"
  START_PROGRAM="start_opensoar"
fi
# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

main_menu () {
while true
do
  if [[ "$MENU_VERSION" == "club" ]]
  then
    club_menu
  else
    normal_menu
  fi
done
}

function normal_menu() {
    ### display main menu ###
    dialog --clear --nocancel --backtitle "OpenVario" \
    --title "[ M A I N - M E N U ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
    OpenSoar   "Start OpenSoar" \
    XCSoar   "Start XCSoar" \
    File   "Copys file to and from OpenVario" \
    System   "Update, Settings, ..." \
    Exit   "Exit to the shell" \
    Reboot "Reboot" \
    Power_OFF "Power OFF" \
    2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        OpenSoar) start_opensoar;;
        XCSoar) start_xcsoar;;
        File) submenu_file;;
        System) submenu_system;;
        Exit) do_shell;;
        Reboot) do_reboot;; 
        Power_OFF) do_power_off;;
    esac
}

function club_menu() {
    ### display main menu  with club version###
    dialog --clear --nocancel --backtitle "OpenVario" \
    --title "[ M A I N - M E N U - C L U B]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
    OpenSoarClub   "Start OpenSoarClub" \
    OpenSoar   "Start OpenSoar" \
    XCSoar   "Start XCSoar" \
    File   "Copys file to and from OpenVario" \
    System   "Update, Settings, ..." \
    Exit   "Exit to the shell" \
    Reboot "Reboot" \
    Power_OFF "Power OFF" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        OpenSoarClub) start_opensoar_club;;
        OpenSoar) start_opensoar;;
        XCSoar) start_xcsoar;;
        File) submenu_file;;
        System) submenu_system;;
        Exit) do_shell;;
        Reboot) do_reboot;; 
        Power_OFF) do_power_off;;
    esac
}


function submenu_file() {

    ### display file menu ###
    dialog --nocancel --backtitle "OpenVario" \
    --title "[ F I L E ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 4 \
    Download_IGC   "Download XCSoar IGC files to USB" \
    Download   "Download XCSoar to USB" \
    Upload   "Upload files from USB to XCSoar" \
    Reset_Data   "Reset complete data files from USB" \
    Back   "Back to Main" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        Download_IGC) download_igc_files;;
        Download) download_files;;
        Upload) upload_files;;
        Reset_Data) reset_data;;
        Exit) ;;
esac
}

function submenu_system() {
    ### display system menu ###
    dialog --nocancel --backtitle "OpenVario" \
    --title "[ S Y S T E M ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 6 \
    Upgrade_Firmware   "Update complete system firmware" \
    Update_System   "Update system software" \
    Update_Maps   "Update Maps files" \
    Calibrate_Sensors   "Calibrate Sensors" \
    Calibrate_Touch   "Calibrate Touch" \
    Settings   "System Settings" \
    Information "System Info" \
    Back   "Back to Main" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        Upgrade_Firmware)
            upgrade_firmware
            ;;
        Update_System)
            update_system
            ;;
        Update_Maps)
            update_maps
            ;;
        Calibrate_Sensors)
            calibrate_sensors
            ;;
        Calibrate_Touch)
            calibrate_touch
            ;;
        Settings)
            submenu_settings
            ;;
        Information)
            show_info
            ;;
        Exit) ;;
    esac
}

function show_info() {
    ### collect info of system and show them in a dialog 
	/usr/bin/system-info.sh > /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" \
           --tailbox /tmp/tail.$$ 30 50
}

function submenu_settings() {
    ### display settings menu ###
    dialog --nocancel --backtitle "OpenVario" \
    --title "[ S Y S T E M ]" \
    --begin 3 4 \
    --menu "You can use the UP/DOWN arrow keys" 15 50 5 \
    Display_Rotation     "Set rotation of the display" \
    LCD_Brightness        "Set display brightness" \
    XCSoar_Language     "Set language used for XCSoar" \
    SSH            "Enable or disable SSH" \
    Back   "Back to Main" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decsion
    case $menuitem in
        Display_Rotation)
            submenu_rotation
            ;;
        LCD_Brightness)
            submenu_lcd_brightness
            ;;
        XCSoar_Language)
            submenu_xcsoar_lang
            ;;
        SSH)
            submenu_ssh
            ;;
        Back) ;;
    esac
}

function submenu_xcsoar_lang() {
    if test -n "$LANG"; then
        XCSOAR_LANG="$LANG"
    else
        XCSOAR_LANG="system"
    fi

    dialog --nocancel --backtitle "OpenVario" \
        --title "[ S Y S T E M ]" \
        --begin 3 4 \
        --menu "Actual Setting is $XCSOAR_LANG \nSelect Language:" 15 50 12 \
         system "Default system" \
         de_DE.UTF-8 "German" \
         fr_FR.UTF-8 "France" \
         it_IT.UTF-8 "Italian" \
         hu_HU.UTF-8 "Hungary" \
         pl_PL.UTF-8 "Poland" \
         cs_CZ.UTF-8 "Czech" \
         sk_SK.UTF-8 "Slowak" \
         lt_LT.UTF-8 "Lithuanian" \
         ru_RU.UTF-8 "Russian" \
         es_ES.UTF-8 "Espanol" \
         nl_NL.UTF-8 "Dutch" \
         2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # update config
    localectl set-locale "$menuitem"
    sync

    export LANG="$menuitem"
}

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
        enabled "Enable SSH permanently" \
        temporary "Enable SSH temporarily (until reboot)" \
        disabled "Disable SSH" \
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
}

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
if [ "$(</sys/class/backlight/lcd/brightness)" = "" ]; then 
  # in case of ESC brightness is empty
  echo "$menuitem" > /sys/class/backlight/lcd/brightness
fi
    submenu_settings
}

function submenu_rotation() {
    TEMP=$(grep "rotation" /boot/config.uEnv)
    if [ -n $TEMP ]; then
        ROTATION=${TEMP: -1}
        dialog --nocancel --backtitle "OpenVario" \
        --title "[ S Y S T E M ]" \
        --begin 3 4 \
        --default-item "${ROTATION}" \
        --menu "Select Rotation:" 15 50 4 \
         0 "Landscape 0 deg" \
         1 "Portrait 90 deg" \
         2 "Landscape 180 deg" \
         3 "Portrait 270 deg" 2>"${INPUT}"

         menuitem=$(<"${INPUT}")

        # update config
        # uboot rotation
        sed -i 's/^rotation=.*/rotation='$menuitem'/' /boot/config.uEnv
        echo "$menuitem" >/sys/class/graphics/fbcon/rotate_all
        dialog --msgbox "New Setting saved !!\n Touch recalibration required !!" 10 50
    else
        dialog --backtitle "OpenVario" \
        --title "ERROR" \
        --msgbox "No Config found !!"
    fi
}

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

function upgrade_firmware() {
    echo "Upgrade Firmware ..." > /tmp/tail.$$
    /usr/bin/fw-upgrade.sh
    echo "firmware upgrade interrupted..."
    echo "==============================="
    sync
}

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

function calibrate_touch() {
    echo "Calibrating Touch ..." >> /tmp/tail.$$
    /usr/bin/ov-calibrate-ts.sh >> /tmp/tail.$$
    dialog --msgbox "Calibration OK!" 10 50
}

# Copy /usb/usbstick/openvario/maps to /home/root/.xcsoar
# Copy only xcsoar-maps*.ipk and *.xcm files
function update_maps() {
    echo "Updating Maps ..." > /tmp/tail.$$
    /usr/bin/update-maps.sh >> /tmp/tail.$$ 2>/dev/null &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar to /usb/usbstick/openvario/download/xcsoar
function download_files() {
    echo "Downloading files ..." > /tmp/tail.$$
    /usr/bin/download-all.sh >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar/logs to /usb/usbstick/openvario/igc
# Copy only *.igc files
function download_igc_files() {
    /usr/bin/download-igc.sh
}

# Copy /usb/usbstick/openvario/upload to /home/root/.xcsoar
function upload_files(){
    echo "Uploading files ..." > /tmp/tail.$$
    /usr/bin/upload-xcsoar.sh >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Reset /usb/usbstick/openvario/upload to /home/root/.xcsoar
function reset_data(){
    echo "Uploading data files ..." > /tmp/tail.$$
    /usr/bin/reset-xcsoar-data.sh >> /tmp/tail.$$ &
    dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}


# datapath with short name: better visibility im OpenSoar/XCSoar
function start_opensoar_club() {
    # reset the profile to standard profile
    cp $DATADIR/.glider_club/GliderClub_Std.prf $DATADIR/XCSoarData/GliderClub.prf
    # start the GliderClub version of opensoar
    /usr/bin/OpenSoar -fly -profile=$DATADIR/XCSoarData/GliderClub.prf \
      -datapath=data/XCSoarData/
    sync
}


function start_opensoar() {
    /usr/bin/OpenSoar -fly -datapath=data/XCSoarData/
    sync
}

function start_xcsoar() {
    /usr/bin/xcsoar -fly -datapath=data/XCSoarData/
    sync
}

function do_reboot(){
    dialog --backtitle "Openvario" \
    --nook --nocancel --pause \
    "Reboot OpenVario ... \\n Press [ESC] for interrupt" 10 30 2 2>&1

    case $? in
        0) reboot;;
    esac
}

function do_power_off(){
    dialog --backtitle "Openvario" \
    --begin 3 4 \
    --defaultno \
    --title "Really Power-OFF ?" --yesno "Really want to Power-OFF" 5 40

    response=$?
    case $response in
        0) shutdown -h now;;
    esac
}

function do_shell(){
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

# set system configs if config.uSys is available (from Upgrade)
cd ~/
if [ -f config.uSys ]; then
  echo "Update system config" > sysconfig.txt
  /usr/bin/update-system-config.sh
elif [ ! -f _config.uSys ]; then
  echo "config.uSys not found" > sysconfig.txt
else
  echo "only backup config found !!!!!" > sysconfig.txt
fi

dialog --nook --nocancel --pause \
"Starting OpenSoar (!)... \\n Press [ESC] for menu" \
10 30 $TIMEOUT 2>&1

case $? in
    0) $START_PROGRAM;;
    *) main_menu;;
esac

main_menu
