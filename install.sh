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
cat > /etc/hostapd/hostapd.conf << EOF
interface=${WIFI_INTERFACE}
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=${CHANNEL}
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${PASSWORD}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Configure dnsmasq
echo -e "${GREEN}Configuring dnsmasq...${NC}"
cat > /etc/dnsmasq.conf << EOF
interface=${WIFI_INTERFACE}
dhcp-range=${IP_ADDRESS},${IP_ADDRESS},255.255.255.0,24h
domain=local
address=/gw.local/${IP_ADDRESS}
EOF

# Configure static IP
echo -e "${GREEN}Configuring static IP...${NC}"
cat > /etc/dhcpcd.conf.append << EOF
interface ${WIFI_INTERFACE}
    static ip_address=${IP_ADDRESS}/24
    nohook wpa_supplicant
EOF

# Configure iptables
echo -e "${GREEN}Configuring iptables...${NC}"
cat > /etc/iptables/rules.v4 << EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A FORWARD -i ${WIFI_INTERFACE} -o eth0 -j ACCEPT
-A FORWARD -i eth0 -o ${WIFI_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
COMMIT
EOF

# Enable IP forwarding
echo -e "${GREEN}Enabling IP forwarding...${NC}"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

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
echo -e "${GREEN}IP Address: ${IP_ADDRESS}${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 