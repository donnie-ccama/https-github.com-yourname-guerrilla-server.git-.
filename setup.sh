#!/bin/bash

# --- GUERRILLA SERVER INSTALLER ---
# Target: Raspberry Pi 5 running Raspberry Pi OS (Bookworm)
# Hardware: External WiFi Adapter (wlan1)

echo ">>> STARTING INSTALLATION..."
echo ">>> Updating repositories..."
apt-get update && apt-get upgrade -y

echo ">>> Installing dependencies..."
# hostapd: Creates the hotspot
# dnsmasq: Handles IP addresses and the 'Captive Portal' redirect
# nginx: Serves the video website
apt-get install -y hostapd dnsmasq nginx netfilter-persistent iptables-persistent

echo ">>> Configuring NetworkManager to IGNORE wlan1..."
# We need manual control over the external card (wlan1). 
# This prevents the OS from trying to use it as a normal client.
cat > /etc/NetworkManager/conf.d/99-unmanaged-devices.conf <<CONF
[keyfile]
unmanaged-devices=interface-name:wlan1
CONF

# Reload NetworkManager to apply the ignore rule
systemctl reload NetworkManager

echo ">>> Setting Static IP for wlan1..."
# We manually assign the gateway IP (192.168.4.1) to the interface
cat > /etc/network/interfaces.d/wlan1 <<NET
auto wlan1
iface wlan1 inet static
    address 192.168.4.1
    netmask 255.255.255.0
NET

echo ">>> Enabling IP Forwarding..."
# Allows traffic to flow correctly (even in offline mode)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo ">>> Configuring Nginx..."
# Remove default site to avoid conflicts
rm /etc/nginx/sites-enabled/default
# Create the web root directory
mkdir -p /var/www/html/video
chown -R www-data:www-data /var/www/html

echo ">>> Unmasking and Enabling Services..."
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
systemctl enable nginx

echo ">>> INSTALLATION COMPLETE."
echo ">>> Please copy the config files (hostapd.conf, dnsmasq.conf, nginx_site.conf) to their respective locations."
echo ">>> Then reboot the Pi."
