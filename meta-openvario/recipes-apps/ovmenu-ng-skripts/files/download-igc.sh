#!/bin/bash

# download in /logs only?
DATA_FOLDER="OpenSoarData"
if [ "$MAIN_APP" = "xcsoar" ]; then
  $DATA_FOLDER="data/XCSoarData"
elif [ "$MAIN_APP" = "OpenSoar" ]; then
  $DATA_FOLDER="data/OpenSoarData"
else 
  $DATA_FOLDER=".xcsoar"
fi

SOAR_DATA_PATH="/home/root/$DATA_FOLDER"

# =========================================================================
# =========================================================================
# =========================================================================
if [  ]; then

if [ -z $DATA_FOLDER ]; then
  echo "DATA_FOLDER empty and not valid!"
else


IGC_PATH="$SOAR_DATA_PATH/logs/"
USB_PATH="/usb/usbstick/openvario/igc"

mkdir -p $USB_PATH    # if not exists

# trap and delete temp files
trap "rm /tmp/menuitem.$$;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM EXIT

filter()
{
    NUM=0
    ls $IGC_PATH -r | egrep '.igc' | while read i ; do
        echo $'\t'$NUM$'\t'$i
        NUM=$(($NUM+1))
    done
}

#---------------------------------------------------------------------------
LINES=$(filter)

IFS=$'\n\t'

if [ -d $IGC_PATH ]; then
    dialog --begin 3 4 --backtitle "OpenVario" --title "Download IGC" \
    --menu "Move using [UP] [DOWN],[Enter] to Select" 22 50 20 $LINES \
    2>/tmp/menuitem.$$
    if [ $? -eq 0 ] ; then
      echo "Downloading File">/tmp/tail.$$
      ITEM=$(cat /tmp/menuitem.$$)
      FILE=$(echo "$LINES" | sed -n 's/\t'$ITEM'\t//p')
      cp $IGC_PATH/$FILE $USB_PATH/$FILE 2>>/tmp/tail.$$
      echo $FILE >>/tmp/tail.$$
      echo "Done !!" >> /tmp/tail.$$
    else
      echo "User Cancel">/tmp/tail.$$
    fi
else
    echo "Directory not Found !!">/tmp/tail.$$
fi

unset IFS

dialog --begin 3 4 --backtitle "OpenVario" --title "Download IGC" --tailbox /tmp/tail.$$ 22 50


fi
# =========================================================================
# =========================================================================
# =========================================================================
else
  echo "With OpenVarioMenu the Downloading of IGC-Files has to be rebuild!"
  echo "No IGC-File can be downloded now!"
  echo "======================================================="
  echo "DONE!"
fi