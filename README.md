# Pi Zero 2 W Repeater Setup

This repository contains everything you need to turn your Raspberry Pi Zero 2 W into a Wi-Fi repeater. The setup creates a wireless access point that bridges to your existing network, effectively extending your Wi-Fi coverage.

## Features

- Creates a wireless access point
- Bridges to existing network
- DHCP server for connected clients
- NAT and port forwarding
- Persistent configuration
- Easy setup with a single script

## Requirements

- Raspberry Pi Zero 2 W
- Raspberry Pi OS (Bullseye or later)
- Internet connection (for initial setup)
- Root access

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/your-username/pi-repeater-setup.git
cd pi-repeater-setup
```

2. Make the install script executable:
```bash
chmod +x install.sh
```

3. Run the installation script as root:
```bash
sudo ./install.sh
```

4. Reboot when prompted

## Configuration

You can modify the following variables in `install.sh` to customize your setup:

- `SSID`: The name of your wireless network
- `PASSWORD`: The password for your wireless network
- `CHANNEL`: The Wi-Fi channel to use
- `IP_ADDRESS`: The IP address of the Pi on the repeater network

## Default Settings

- SSID: `PiRepeater`
- Password: `raspberry`
- IP Address: `192.168.4.1`
- Subnet: `192.168.4.0/24`

## Troubleshooting

If you encounter issues:

1. Check the status of services:
```bash
systemctl status hostapd
systemctl status dnsmasq
```

2. View logs:
```bash
journalctl -u hostapd
journalctl -u dnsmasq
```

3. Verify iptables rules:
```bash
iptables -L
iptables -t nat -L
```

## Contributing

Feel free to submit issues and pull requests. All contributions are welcome!

## License

This project is licensed under the MIT License - see the LICENSE file for details. 