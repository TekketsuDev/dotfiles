#!/usr/bin/env bash
set -e

sudo pacman -S --noconfirm openvpn network-manager-openvpn
yay -S --noconfirm openvpn-update-systemd-resolved

sudo systemctl enable systemd-resolved --now
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

OVPN_FILE="$HOME/Downloads/Spain.ovpn"
VPN_NAME="$(basename "$OVPN_FILE" .ovpn)"
USERNAME="$IKEv2_USERNAME"
PASSWORD="$IKEv2_PASSWORD"

tmp_file=$(mktemp)
sed 's|/etc/openvpn/update-resolv-conf|/usr/bin/update-systemd-resolved|g' "$OVPN_FILE" > "$tmp_file"
mv "$tmp_file" "$OVPN_FILE"

grep -q 'up-restart' "$OVPN_FILE" || sed -i '/script-security 2/a up-restart' "$OVPN_FILE"
grep -q 'down-pre' "$OVPN_FILE" || sed -i '/down \/usr\/bin\/update-systemd-resolved/a down-pre' "$OVPN_FILE"

grep -q 'dhcp-option DOMAIN-ROUTE .' "$OVPN_FILE" || echo 'dhcp-option DOMAIN-ROUTE .' >> "$OVPN_FILE"

nmcli connection import type openvpn file "$OVPN_FILE"

nmcli connection modify "$VPN_NAME" +vpn.data "username=$USERNAME"
nmcli connection modify "$VPN_NAME" vpn.secrets "password=$PASSWORD"
nmcli connection modify "$VPN_NAME" connection.autoconnect yes

nmcli connection up id "$VPN_NAME"
