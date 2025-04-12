#!/bin/bash

# Exit on error
set -e

# Create bridge interface
ip link add name br0 type bridge
ip link set br0 up

# Add wlan0 to bridge
ip link set wlan0 up
ip link set wlan0 master br0

# Configure wpa_supplicant for OffGridNet
cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="OffGridNet"
    psk="raspberry"
    key_mgmt=WPA-PSK
}
EOF

# Start wpa_supplicant
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf

echo "Bridge interface setup complete!" 