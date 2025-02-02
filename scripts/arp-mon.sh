#!/bin/bash

iFace="eth0" # Change to your actual interface if necessary (e.g., "wlan0")

##
# Check and install dependencies only if they are missing
##
function check_and_install_deps() {
    # List of required packages
    local pkgs=(net-tools git build-essential libpcap-dev)
    local missing=()

    # Identify which packages are missing
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    # Install missing packages if necessary
    if ((${#missing[@]} > 0)); then
        echo "Installing missing packages: ${missing[@]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    else
        echo "All required packages are already installed."
    fi
}

##
# Generate a locally administered random MAC (first byte = 0x02)
##
function random_mac() {
    echo "02$(hexdump -n5 -e '/1 ":%02X"' /dev/urandom)"
}

##
# Get current MAC of the interface
##
function get_mac() {
    ifconfig "$iFace" 2>/dev/null | awk '/ether/ {print $2}'
}

origMAC=$(get_mac)

##
# Change the MAC to a random one
##
function change_mac() {
    echo
    echo "Changing MAC address on $iFace ..."
    echo "Original MAC: $origMAC"

    local newMAC
    newMAC=$(random_mac)

    # Bring the interface down before changing MAC
    sudo ifconfig "$iFace" down
    sudo ifconfig "$iFace" hw ether "$newMAC"

    echo "     New MAC: $(get_mac)"
}

##
# Reset the MAC to the original address
##
function reset_mac() {
    echo
    echo "Resetting MAC Address..."
    echo "Current MAC: $(get_mac)"

    disable_iface
    sudo ifconfig "$iFace" hw ether "$origMAC"
    enable_iface

    echo "  Reset MAC: $(get_mac)"
}

# Ensure we reset MAC if the script is interrupted
trap reset_mac EXIT

function disable_iface() {
    echo
    echo "Disabling $iFace ..."
    sudo ifconfig "$iFace" down
}

function enable_iface() {
    echo
    echo "Enabling $iFace ..."
    sudo ifconfig "$iFace" up
}

##
# MAIN
##

# Step 1: Check & install dependencies if missing
check_and_install_deps

# Step 2: Enable IP forwarding (for Debian/Raspbian)
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Step 3: Change MAC and bring interface back up
change_mac
enable_iface

# (Optional) Start Bettercap
sudo bettercap --iface "$iFace" --caplet ../caplets/arp-mon.cap

# Wait for user to press Enter
echo
read -p "Press [Enter] to stop..."
