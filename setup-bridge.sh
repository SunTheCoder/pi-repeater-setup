#!/bin/bash

# Exit on error
set -e

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
systemctl stop wpa_supplicant
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf

echo "WiFi configuration complete!" 