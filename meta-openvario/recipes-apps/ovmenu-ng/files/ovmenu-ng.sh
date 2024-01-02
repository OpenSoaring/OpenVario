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

#------------------------------------------------------------------------------
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

while true
do
   /usr/bin/OpenVarioMenu
   wait
   do_shell
done

