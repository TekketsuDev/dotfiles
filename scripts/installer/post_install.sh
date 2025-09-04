#!/usr/bin/env bash
set -e

echo "🛠️ Running post-install setup..."

ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

echo "🗣️ Generating locale..."
sed -i 's/^#es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

read -rp "🧩 Enter hostname: " MY_HOSTNAME
echo "$MY_HOSTNAME" > /etc/hostname

cat <<EOF > /etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.1.1       $MY_HOSTNAME.localdomain $MY_HOSTNAME
EOF

read -rp "Enter username to create: " NEW_USER
useradd -m -G wheel "$NEW_USER"
passwd "$NEW_USER"

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "✅ Enabling NetworkManager and SSH..."
systemctl enable NetworkManager
systemctl enable sshd

echo "🔧 (Re)Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

chsh -s /bin/zsh "$NEW_USER"

if [ -f "/home/$NEW_USER/dotfiles/scripts/auto_install_modules.sh" ]; then
    echo "📦 Running modular install for $NEW_USER"
    su - "$NEW_USER" -c "bash ~/dotfiles/scripts/auto_install_modules.sh"
fi
