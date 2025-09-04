# === backup_efi.sh ===
# Usage: ./backup_efi.sh /dev/sdX

#!/usr/bin/env bash
set -e

DISK="/dev/${1##*/}"
EFI_BACKUP_NAME="efi_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

read -rp "🛡️  Do you want to backup the current EFI partition? [y/N]: " BACKUP_EFI
if [[ "$BACKUP_EFI" =~ ^[Yy]$ ]]; then

    EFIPART=$(lsblk -rpno NAME,MOUNTPOINT | awk '$2=="/boot/efi" {print $1}')
    if [[ -z "$EFIPART" ]]; then
        EFIPART=$(lsblk -rpno NAME,PARTTYPE | grep 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b' | awk '{print $1}' | head -n1)
    fi

    echo "📦 Where do you want to store the backup?"
    echo "  1) Save to USB (e.g. /run/media/...)"
    echo "  2) Send to Proxmox via SCP"
    read -rp "→ Choose [1/2]: " DEST_OPT

    sudo mkdir -p /mnt/efiback
    sudo mount "$EFIPART" /mnt/efiback
    tar -czvf "/tmp/$EFI_BACKUP_NAME" -C /mnt/efiback .
    sudo umount /mnt/efiback

    if [[ "$DEST_OPT" == "1" ]]; then
        read -rp "→ USB path: " USB_DEST
        cp "/tmp/$EFI_BACKUP_NAME" "$USB_DEST/"
        echo "✅ EFI backup saved to: $USB_DEST/$EFI_BACKUP_NAME"
    elif [[ "$DEST_OPT" == "2" ]]; then
        read -rp "→ Proxmox user@ip: " PROX_USER
        read -rp "→ Remote path: " REMOTE_PATH
        scp "/tmp/$EFI_BACKUP_NAME" "$PROX_USER:$REMOTE_PATH"
        echo "✅ EFI backup sent to: $PROX_USER:$REMOTE_PATH/$EFI_BACKUP_NAME"
    else
        echo "⚠️ Invalid option. Backup saved to /tmp/$EFI_BACKUP_NAME"
    fi
fi
