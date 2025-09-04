#!/bin/bash

# Ensure OpenSSH is installed
sudo pacman -S --noconfirm openssh

# Enable and start SSH service
sudo systemctl enable sshd
sudo systemctl start sshd

# Generate SSH key (skip if exists)
if [[ ! -f ~/.ssh/id_rsa ]]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "SSH key generated!"
else
    echo "SSH key already exists, skipping generation."
fi

# Ask user for LAN IPs to distribute the key
echo "Enter the IP addresses of your LAN machines (separated by spaces):"
read -r ips

for ip in $ips; do
    echo "Copying SSH key to $ip..."
    ssh-copy-id -o StrictHostKeyChecking=no "$USER@$ip"
done

# (Optional) Secure SSH: Disable password authentication
echo "Do you want to disable password authentication for SSH? (y/n)"
    read -r disable_pass
if [[ $disable_pass == "y" ]]; then
    sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    echo "Password authentication disabled!"
fi


