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

# Check if connected to OffGridNet
if ! iwconfig wlan0 | grep -q "OffGridNet"; then
    echo -e "${RED}Not connected to OffGridNet. Please connect first.${NC}"
    exit 1
fi

# Stop only hostapd and dnsmasq, leave wpa_supplicant running
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
cp $(dirname "$0")/configs/dhcpcd.conf.append /etc/dhcpcd.conf.append
cat /etc/dhcpcd.conf.append >> /etc/dhcpcd.conf

# Configure iptables for NAT
echo -e "${GREEN}Configuring iptables...${NC}"
# Flush existing rules
iptables -F
iptables -t nat -F

# Set up NAT
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o wlan0 -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Enable and start services
echo -e "${GREEN}Enabling and starting services...${NC}"
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Start services
systemctl start hostapd
systemctl start dnsmasq

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