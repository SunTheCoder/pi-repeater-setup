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

# Stop services
systemctl stop hostapd
systemctl stop dnsmasq

# Configure hostapd to use wlan0
echo -e "${GREEN}Configuring hostapd...${NC}"
cat > /etc/hostapd/hostapd.conf << EOF
interface=wlan0
driver=nl80211
ssid=OffGridNetRepeater
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=raspberry
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Configure dnsmasq
echo -e "${GREEN}Configuring dnsmasq...${NC}"
cat > /etc/dnsmasq.conf << EOF
interface=wlan0
dhcp-range=192.168.5.2,192.168.5.254,255.255.255.0,24h
domain=local
address=/gw.local/192.168.5.1
EOF

# Configure network interfaces
echo -e "${GREEN}Configuring network interfaces...${NC}"
cat > /etc/network/interfaces.d/wlan0 << EOF
allow-hotplug wlan0
iface wlan0 inet static
    address 192.168.5.1
    netmask 255.255.255.0
    network 192.168.5.0
    broadcast 192.168.5.255
EOF

# Configure iptables for NAT
echo -e "${GREEN}Configuring iptables...${NC}"
# Flush existing rules
iptables -F
iptables -t nat -F

# Set up NAT
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wlan0 -j ACCEPT
iptables -A FORWARD -i wlan0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

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