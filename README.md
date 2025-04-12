# OffGridNet Extender

A simple script to configure a Raspberry Pi Zero W as a range extender for OffGridNet.

## What it does

- Connects to OffGridNet
- Enables packet forwarding
- Sets up NAT
- Extends the network range

## How to use

1. Clone this repository
2. Make the script executable:
   ```bash
   chmod +x extend.sh
   ```
3. Run the script:
   ```bash
   sudo ./extend.sh
   ```
4. Reboot when prompted

## How to verify it's working

1. Check if connected to OffGridNet:
   ```bash
   iwconfig wlan0
   ```

2. Check if IP forwarding is enabled:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   ```
   Should show: 1

3. Check if NAT is set up:
   ```bash
   sudo iptables -t nat -L
   ```
   Should show MASQUERADE rule

## Testing the range extension

1. Find a spot where OffGridNet signal is weak
2. Place the Pi Zero halfway between that spot and the OffGridNet source
3. You should now get better signal in the previously weak spot 