#!/usr/bin/env bash
set -e

echo "🚀 Installing Arch base system..."

loadkeys es
timedatectl set-ntp true

timedatectl set-timezone Europe/Madrid

reflector --country Spain,Germany,France --age 12 --sort rate --save /etc/pacman.d/mirrorlist

echo "📦 Installing base system to /mnt..."
pacstrap -K /mnt base base-devel linux linux-firmware \
    vim zsh sudo git stow networkmanager grub efibootmgr \
    man-db man-pages lsb-release wget curl unzip zip openssh

genfstab -U /mnt >> /mnt/etc/fstab
echo "📝 fstab generated"

# Copy dotfiles and post-install into new system
mkdir -p /mnt/home/work
cp -r ~/dotfiles /mnt/home/tekketsu/
cp scripts/packages/arch/post_install.sh /mnt/root/

echo "🌀 Chroot into system and run:"
echo "    arch-chroot /mnt"
echo "    bash /root/post_install.sh"
echo "    reboot                    "
