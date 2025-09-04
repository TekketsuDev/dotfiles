#!/usr/bin/env bash
set -e

echo "🔍 Available Disks:"
lsblk -d -e7 -o NAME,SIZE,MODEL

read -rp "👉 Enter target disk (e.g. sda or nvme0n1): " disk
DISK="/dev/$disk"

echo
echo "🧱 Partition layout to be created:"
printf "%-10s %-15s %-15s %-10s %-30s\n" "Partition" "First Sector" "Last Sector" "Code" "Description"
printf "%-10s %-15s %-15s %-10s %-30s\n" "---------" "-------------" "------------" "------" "-----------"
printf "%-10s %-15s %-15s %-10s %-30s\n" "1" "default" "+512M" "ef00" "EFI System Partition"
printf "%-10s %-15s %-15s %-10s %-30s\n" "2" "default" "+4G"   "ef02" "BIOS Boot Partition"
printf "%-10s %-15s %-15s %-10s %-30s\n" "3" "default" "rest" "8309" "Linux LVM or root"
printf "%-10s %-15s %-15s %-10s %-30s\n" "4(opt)" "default" "rest" "8300" "Backup volume /backup"


echo "📐 Creating partitions..."
#sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" "$DISK"
#sgdisk -n 2:0:+4G    -t 2:ef02 -c 2:"BIOS Boot Partition" "$DISK"
#sgdisk -n 3:0:0      -t 3:8309 -c 3:"Linux Root or LVM" "$DISK"

read -rp "➕ Do you want to add a separate backup partition? [y/N]: " ADD_BACKUP
if [[ "$ADD_BACKUP" =~ ^[Yy]$ ]]; then
    read -rp "💾 How much space for backup? (e.g. +100G): " BACKUP_SIZE
    BACKUP_IDX=4
    sgdisk -n ${BACKUP_IDX}:0:${BACKUP_SIZE} -t ${BACKUP_IDX}:8300 -c ${BACKUP_IDX}:"Backup Partition" "$DISK"
    sleep 1
    BACKUPPART="${DISK}${BACKUP_IDX}"
fi

