#!/bin/bash

if [ -e "./config.uSys" ]
then
    echo "'config.uSys' exist!!"
    source ./config.uSys
    
    # ==================== SSH ===============================
    if [ ! "$SSH" == "" ]; then 
        echo "SSH            = $SSH"
        case "$SSH" in
        enabled)
            /bin/systemctl  enable --quiet --now dropbear.socket
            /bin/systemctl   start --quiet --now dropbear.socket
            echo " [####======] SSH has been enabled permanently.";;
        temporary)
            /bin/systemctl disable --quiet --now dropbear.socket
            /bin/systemctl   start --quiet --now dropbear.socket
            echo " [####======] SSH has been enabled temporarily.";;
        disabled)
            /bin/systemctl  disable --quiet --now dropbear.socket
            echo " [####======] SSH has been disabled.";;
        esac
    fi
    # ==================== Brightness ========================
    if [ ! "$BRIGHTNESS" == "" ]; then 
        echo " [####======] Brightness set to $BRIGHTNESS"
        echo $BRIGHTNESS > /sys/class/backlight/lcd/brightness
        # read -t 5 -p "Hit ENTER to continue or wait 5 seconds ..."
    fi
    # ==================== End ===============================
    mv ./config.uSys ./_config.uSys
    exit
fi

