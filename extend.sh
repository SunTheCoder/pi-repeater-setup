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

echo -e "${GREEN}Setting up OffGridNet extender...${NC}"

# Configure wpa_supplicant
echo -e "${GREEN}Configuring connection to OffGridNet...${NC}"
cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="OffGridNet"
    psk="Datathug2024!"
    key_mgmt=WPA-PSK
}
EOF

# Set permissions
chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf

# Set up NAT
iptables -t nat -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# Save iptables rules
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# Create startup script to restore iptables rules
cat > /etc/network/if-pre-up.d/iptables << EOF
#!/bin/sh
iptables-restore < /etc/iptables/rules.v4
EOF

chmod +x /etc/network/if-pre-up.d/iptables

# Restart networking
systemctl restart wpa_supplicant

echo -e "${GREEN}Setup complete! This Pi will now extend OffGridNet's range.${NC}"
echo -e "${GREEN}To verify it's working:${NC}"
echo -e "1. Check connection: ${GREEN}iwconfig wlan0${NC}"
echo -e "2. Check IP forwarding: ${GREEN}cat /proc/sys/net/ipv4/ip_forward${NC}"
echo -e "3. Check NAT rules: ${GREEN}iptables -t nat -L${NC}"

# Prompt for reboot
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi 