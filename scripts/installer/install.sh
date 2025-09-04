#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

print_logo () {
  echo -e "\e[38;5;39m________      __    __           __                       ________"
  echo -e "\\_    _/ ___ |  | _|  | __ _____/  |_ __ __  ________ __  \\______ \\   _______  __"
  echo -e "  |  |_/ __ \\|  |/ /  |/ // __ \\   __\\  |  \\/  ___/  |  \\  |    |  \\_/ __ \\  \\/ /"
  echo -e "  |  |\\  ___/|    <|    <\\  ___/|  | |  |  /\\___ \\|  |  /  |  __|   \\  ___/\\   /"
  echo -e "  |__| \\___  >__|_ \\__|_ \\\\___  >__| |____//____  >____/  /_______  /\\___  >\\_/"
  echo -e "           \\/     \\/    \\/    \\/                \\/                \\/     \\/"
  echo -e ""
  echo -e "\e[1;36m    Arch build system\e[0m"
  echo
  echo -e "\e[1;33m    This guided installer is intended to go through all the installation process"
  echo -e "    to get the full working system.\e[0m"
  echo
  echo -e "\e[0;32m    Although it has a modular approach, not all scripts work in a modular way.\e[0m"
  echo
  echo -e "\e[0;36m    Start by running this installation script through arch installation media\e[0m"
  echo
  echo -e "\e[1;35m    - Give network access via ethernet or iwctl, normally:"
  echo -e "      \"station wlan0 connect __YOUR_SSID__\"\e[0m"
  echo
  echo -e "\e[1;35m    - The script will need reboots so you must execute:"
  echo -e "      /dotfiles/scripts/installer/post_install.sh after it reboots\e[0m"
  echo
  echo -e "\e[0;31m    If you just want to get the configuration files:"
  echo -e "      use dotfiles/scripts/installer/stow.sh and avoid this script.\e[0m"
  echo
}

clear
print_logo
# 0. BIOS/Settings
IS_VM=$(systemd-detect-virt)

if [[ "$IS_VM" == "none" ]]; then
    read -rp "Have you disabled BIOS Secure Boot? [y/N]"
    BIOS=false
    if [ ! -d /sys/firmware/efi ] && [[ ! "$BIOS" =~ ^[Yy]$ ]]; then
        echo " Rebooting your system into BIOS (if possible)"
        echo "     - [?] Disable Secure Boot"
        echo "     - [ ] Enable UEFI"
        sleep 5
        systemctl reboot --firmware-setup
    fi
else
    echo "⚙️  Detected virtual environment: $IS_VM"
    echo "    Skipping EFI/Secure Boot check (running in VM)"
fi

# 1. Dualboot
if lsblk -f | grep -iq 'Microsoft'; then
    echo "✅ Found Microsoft EFI partition — assuming dualboot"
    DUALBOOT=true
elif findmnt -rn -o TARGET | grep -q '/boot/efi' && [[ -d /boot/efi/EFI/Microsoft ]]; then
    echo "✅ Found EFI/Microsoft boot entry — assuming dualboot"
    DUALBOOT=true
else
     read -rp "No detected EFI partition it's dual boot with Windows? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        DUALBOOT=true
    else
        DUALBOOT=false
    fi
fi

# 2. Target disk
lsblk -d -p -e1,7,11 -o NAME,SIZE,MODEL,TYPE
read -rp "🖴 Enter disk to use (e.g., /dev/nvme0n1): " DISK

read -rp "🧹 Wipe all data? " WIPE

if [[ "$WIPE" =~ ^[Yy]$ ]]; then

    bash $SCRIPT_DIR/partitioning/wipe_disk.sh "/dev/$DISK"
fi

# 3. Backup EFI
if [[ "$DUALBOOT" == true ]]; then
    bash $SCRIPT_DIR/partitioning/backup_efi.sh "/dev/$DISK"
fi

# 4. Partitioning
read -rp "🧹 Run full disk setup (wipe, partition, format)? [y/N]: " DO_DISK_SETUP
if [[ "$DO_DISK_SETUP" =~ ^[Yy]$ ]]; then

    source $SCRIPT_DIR/partitioning/box.sh "/dev/$DISK"

    source "$SCRIPT_DIR/partitioning/create_partitions_sgdisk.sh" "/dev/$DISK" "$EXPORTED_PHYSICAL_PARTITIONS_DEF"
if findmnt /dev/sda >/dev/null ; then
    echo "Desmontando activamente /dev/sda y sus posibles montajes anidados..."
    # El -R es para desmontajes recursivos, útil si hay submontajes.
    # El -l es para lazy unmount, por si está muy ocupado.
    umount -Rlf /dev/sda* 2>/dev/null || true
fi
# Notificar al kernel de los cambios
partprobe /dev/sda
udevadm settle

    source "$SCRIPT_DIR/partitioning/format_and_mount.sh" \
        "${EFI_PART_DEVICE}" \
        "${ROOT_PART_DEVICE}" \
        "${BACKUP_PART_DEVICE:-}" \
        "${DUALBOOT:-false}" \
        "${SELECTED_FS_LAYOUT}" \
        "${EXPORTED_BTRFS_SUBVOLUME_NAMES:-}" \
        "${EXPORTED_BTRFS_SUBVOLUME_PURPOSES:-}" \
        "${EXPORTED_BTRFS_SUBVOLUME_MOUNTS:-}"
fi

# 5. Dual boot setup
if [[ "$DUALBOOT" == true ]]; then
    bash $SCRIPT_DIR/partitioning/setup_dualboot.sh "$EFI_PART"
fi
