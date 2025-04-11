#!/bin/bash

# Exit on error
set -e

# Configuration variables
SSID="PiRepeater"
PASSWORD="raspberry"
CHANNEL="6"
WIFI_INTERFACE="wlan0"
BRIDGE_INTERFACE="br0"
IP_ADDRESS="192.168.4.1"
SUBNET="192.168.4.0/24"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

echo -e "${GREEN}Starting Pi Repeater Setup...${NC}"

# Install required packages
echo -e "${GREEN}Installing required packages...${NC}"
apt-get update
apt-get install -y hostapd dnsmasq iptables-persistent

# Stop services before configuration
systemctl stop hostapd
systemctl stop dnsmasq

# Configure hostapd
echo -e "${GREEN}Configuring hostapd...${NC}"
envsubst < $(dirname "$0")/configs/hostapd.conf > /etc/hostapd/hostapd.conf

# Configure dnsmasq
echo -e "${GREEN}Configuring dnsmasq...${NC}"
envsubst < $(dirname "$0")/configs/dnsmasq.conf > /etc/dnsmasq.conf

# Configure static IP
echo -e "${GREEN}Configuring static IP...${NC}"
envsubst < $(dirname "$0")/configs/dhcpcd.conf.append > /etc/dhcpcd.conf.append

# Configure iptables
echo -e "${GREEN}Configuring iptables...${NC}"
envsubst < $(dirname "$0")/configs/iptables.rules.v4 > /etc/iptables/rules.v4

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Install and enable systemd service
echo -e "${GREEN}Installing systemd service...${NC}"
cp $(dirname "$0")/systemd/pi-repeater.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable pi-repeater.service

# Enable and start services
echo -e "${GREEN}Enabling and starting services...${NC}"
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
systemctl start hostapd
systemctl start dnsmasq
systemctl start pi-repeater.service

# Apply iptables rules
echo -e "${GREEN}Applying iptables rules...${NC}"
iptables-restore < /etc/iptables/rules.v4

echo -e "${GREEN}Setup complete! The Pi is now configured as a repeater.${NC}"
echo -e "${GREEN}SSID: ${SSID}${NC}"
echo -e "${GREEN}Password: ${PASSWORD}${NC}"
echo -e "${GREEN}IP Address: ${IP_ADDRESS}${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 