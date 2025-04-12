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

echo -e "${GREEN}Starting Pi Repeater Configuration...${NC}"

# Stop and disable services we don't need
echo -e "${GREEN}Disabling unnecessary services...${NC}"
systemctl mask networking.service dhcpcd.service
mv /etc/network/interfaces /etc/network/interfaces~ 2>/dev/null || true
sed -i '1i resolvconf=NO' /etc/resolvconf.conf

# Enable required services
echo -e "${GREEN}Enabling required services...${NC}"
systemctl enable systemd-networkd.service systemd-resolved.service
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Configure wpa_supplicant for AP mode
echo -e "${GREEN}Configuring wpa_supplicant for AP mode...${NC}"
cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="OffGridNetRepeater"
    mode=2
    key_mgmt=WPA-PSK
    psk="raspberry"
    frequency=2412
}
EOF

chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Configure network interfaces
echo -e "${GREEN}Configuring network interfaces...${NC}"
cat > /etc/systemd/network/08-wlan0.network << EOF
[Match]
Name=wlan0
[Network]
Address=192.168.5.1/24
IPMasquerade=yes
IPForward=yes
DHCPServer=yes
[DHCPServer]
DNS=192.168.4.1
EOF

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Configure wpa_supplicant services
echo -e "${GREEN}Configuring wpa_supplicant services...${NC}"
systemctl disable wpa_supplicant.service
systemctl enable wpa_supplicant@wlan0.service

echo -e "${GREEN}Setup complete! The Pi is now configured as a repeater.${NC}"
echo -e "${GREEN}SSID: OffGridNetRepeater${NC}"
echo -e "${GREEN}Password: raspberry${NC}"
echo -e "${GREEN}IP Address: 192.168.5.1${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 