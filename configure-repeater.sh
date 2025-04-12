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

# Make sure wpa_supplicant is running for OffGridNet connection
systemctl restart wpa_supplicant

# Wait for connection to OffGridNet
echo -e "${GREEN}Waiting for connection to OffGridNet...${NC}"
sleep 10

# Check if connected
if ! iwconfig wlan0 | grep -q "OffGridNet"; then
    echo -e "${RED}Failed to connect to OffGridNet. Please check your connection and try again.${NC}"
    exit 1
fi

# Configure iptables for NAT
echo -e "${GREEN}Configuring iptables...${NC}"
# Flush existing rules
iptables -F
iptables -t nat -F

# Set up NAT
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

echo -e "${GREEN}Setup complete! The Pi is now configured as a repeater.${NC}"
echo -e "${GREEN}Your Pi is connected to OffGridNet and will forward traffic.${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 