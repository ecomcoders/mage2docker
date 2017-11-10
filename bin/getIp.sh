#!/usr/bin/env bash

INTERFACE="$1"

# Check for Apple
IPCONFIG=`which ipconfig`

# Check for linux
IFCONFIG=`which ifconfig`

if [ ! -z $IPCONFIG ]
    then
        ipconfig getifaddr $INTERFACE
elif [ ! -z $IFCONFIG ]
    then
        # see https://askubuntu.com/questions/560412/displaying-ip-address-on-eth0-interface
        # for more variations if this fails
        ip -f inet addr show $1 | grep -Po 'inet \K[\d.]+'
else
    echo "No such network interface found $INTERFACE"
fi

