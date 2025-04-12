#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

echo -e "${GREEN}Starting OffGridNet Extender Configuration...${NC}"

# Configure wpa_supplicant to connect to OffGridNet
echo -e "${GREEN}Configuring connection to OffGridNet...${NC}"
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

chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Configure iptables for forwarding
echo -e "${GREEN}Configuring packet forwarding...${NC}"
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Restart wpa_supplicant to apply changes
systemctl restart wpa_supplicant

echo -e "${GREEN}Setup complete! This Pi will now extend the OffGridNet network.${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 