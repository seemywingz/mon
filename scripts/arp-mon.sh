#!/bin/bash

function get_mac {
    ifconfig $iFace | awk '/ether/{print $2}'
}
origMAC=$(get_mac)

function change_mac {
    echo
    echo "Changing MAC address..."
    echo "Original MAC: $(get_mac)"
    # sudo ifconfig $iFace down
    sudo ifconfig $iFace ether 90:1b:1c:0b:15:e0
    echo "     New MAC: $(get_mac)"
}

function reset_mac {
    echo
    echo "Resetting MAC Address..."
    echo "Current MAC: $(get_mac)"
    disable_iface
    sudo ifconfig $iFace ether $origMAC
    enable_iface
    echo "  Reset MAC: $(get_mac)"
}
trap reset_mac EXIT

function disable_iface {
    echo
    echo "Disabling $iFace ..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo networksetup -setairportpower $iFace off
    fi
    sudo ifconfig $iFace down
}

function enable_iface {
    echo
    echo "Enabling $iFace ..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo networksetup -setairportpower $iFace on
    fi
    sudo ifconfig $iFace up
}

# Configure the interface based on the OS
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    iFace="eth0"
    sudo apt-get install git build-essential libpcap-dev
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    iFace="en0"
    # Enable Packet forwarding
    echo "Enabling Packet Forwarding..."
    sudo sysctl -w net.inet.ip.forwarding=1
fi

disable_iface
change_mac
enable_iface

# Start Bettercap
# sudo bettercap --iface $iFace --caplet ../caplets/arp-mon.cap

# wait for the user to press enter
echo
read -p "Press [Enter] to stop..."
