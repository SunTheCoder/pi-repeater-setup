#!/bin/bash

# Exit on error
set -e

# Configuration variables
export SSID="OffGridNetRepeater"
export PASSWORD="raspberry"
export CHANNEL="6"

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

# Stop services before configuration
systemctl stop hostapd
systemctl stop dnsmasq

# Configure hostapd
echo -e "${GREEN}Configuring hostapd...${NC}"
cp $(dirname "$0")/configs/hostapd.conf /etc/hostapd/hostapd.conf

# Configure dnsmasq
echo -e "${GREEN}Configuring dnsmasq...${NC}"
cp $(dirname "$0")/configs/dnsmasq.conf /etc/dnsmasq.conf

# Configure static IP
echo -e "${GREEN}Configuring static IP...${NC}"
cat $(dirname "$0")/configs/dhcpcd.conf.append >> /etc/dhcpcd.conf

# Configure iptables
echo -e "${GREEN}Configuring iptables...${NC}"
cat > /etc/iptables/rules.v4 << EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o wlan0 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A FORWARD -i wlan1 -o wlan0 -j ACCEPT
-A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
COMMIT
EOF

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Enable and start services
echo -e "${GREEN}Enabling and starting services...${NC}"
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
systemctl start hostapd
systemctl start dnsmasq

# Apply iptables rules
echo -e "${GREEN}Applying iptables rules...${NC}"
iptables-restore < /etc/iptables/rules.v4

echo -e "${GREEN}Setup complete! The Pi is now configured as a repeater.${NC}"
echo -e "${GREEN}SSID: ${SSID}${NC}"
echo -e "${GREEN}Password: ${PASSWORD}${NC}"
echo -e "${GREEN}IP Address: 192.168.5.1${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 