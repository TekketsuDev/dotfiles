# === setup_dualboot.sh ===
# Usage: ./setup_dualboot.sh /dev/sdXY
#!/usr/bin/env bash
set -e

EFI_PART="$1"

echo "🔧 Installing GRUB with dual boot support..."
mount --mkdir "$EFI_PART" /boot

if ! pacman -Qi grub efibootmgr &>/dev/null; then
  echo "📦 Installing GRUB and efibootmgr..."
  pacman -S --noconfirm grub efibootmgr os-prober
fi

os-prober || echo "⚠️ os-prober did not detect Windows, make sure it's installed."

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ Dual boot setup complete. GRUB now includes Windows if detected."

