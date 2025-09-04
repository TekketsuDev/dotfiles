# === luks_encrypt.sh ===
# Usage: source ./luks_encrypt.sh /dev/sdX3

#!/usr/bin/env bash
set -e

PART="$1"
ROOT_MAPPED="$PART"

read -rp "🔐 Encrypt root partition with LUKS? [y/N]: " ENCRYPT
if [[ "$ENCRYPT" =~ ^[Yy]$ ]]; then
    cryptsetup luksFormat "$PART"
    cryptsetup open "$PART" cryptroot
    ROOT_MAPPED="/dev/mapper/cryptroot"
    ENCRYPTED="true"
else
    ENCRYPTED="false"
fi

export ROOT_MAPPED ENCRYPTED

