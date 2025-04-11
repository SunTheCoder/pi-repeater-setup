#!/bin/bash

# Exit on error
set -e

# Configuration
WWW_DIR="/var/www/html"
REDIRECT_IP="192.168.4.1"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Create www directory if it doesn't exist
mkdir -p ${WWW_DIR}

# Copy splash page
cp $(dirname "$0")/../www/index.html ${WWW_DIR}/

# Configure dnsmasq to redirect all DNS queries to the splash page
cat > /etc/dnsmasq.conf.append << EOF
# Redirect all DNS queries to the splash page
address=/#/${REDIRECT_IP}
EOF

# Restart dnsmasq to apply changes
systemctl restart dnsmasq

echo "Splash page setup complete!"
echo "The splash page will be served at http://${REDIRECT_IP}" 