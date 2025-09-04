#!/usr/bin/env bash

set -euo pipefail

# === Input Parameters ===
DUALBOOT="$1"

declare -A LAYOUTS

LAYOUTS["default"]=$'1|+512M|ef00|EFI\n3|rest|8309|Root'
LAYOUTS["dualboot"]=$'1|+512M|ef00|EFI\n2|+4M|ef02|BIOS Boot\n3|rest|8309|Root'
LAYOUTS["root+backup"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8300|Backup'
LAYOUTS["separate_home"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8302|Home'
LAYOUTS["root+media"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8301|Media'

# === Partition Layout Selection ===

show_layout_preview() {
    for layout_name in "${!LAYOUTS[@]}"; do
        local layout_string="${LAYOUTS[$layout_name]}"

        echo -e "\n🔧 Layout: $layout_name"
        printf "%-4s %-10s %-6s %-30s\n" "Num" "Size" "Code" "Description"
        printf "%-4s %-10s %-6s %-30s\n" "----" "----------" "------" "------------------------------"

        while IFS= read -r line; do
            IFS="|" read -r actual_num size code desc <<< "$line"
            printf "%-4s %-10s %-6s %-30s\n" "$actual_num" "$size" "$code" "$desc"
          done <<< "$layout_string"
        done
        echo
        return 0
}


show_layout_preview

# === Select Root Disk ===
echo -e "\n📂 Choose root disk:"
lsblk -d -p -e1,7,11 -o NAME,SIZE,MODEL,TYPE
read -rp "→ Root disk (e.g. /dev/nvme0n1): " ROOT_DISK

# === Partitioning Based on Layout Selection ===
echo -e "\n🛡️ Partitioning root disk: $ROOT_DISK"
sgdisk --zap-all "$ROOT_DISK"

PART_LAYOUT="${LAYOUTS[$LAYOUT_KEY]}"

while IFS= read -r line; do
  IFS="|" read -r num size code desc <<< "$line"
  part_dev="${ROOT_DISK}${num}"
  if [[ "$desc" == *"EFI"* ]]; then
    EFI_PART="$part_dev"
  elif [[ "$desc" == *"Root"* ]]; then
    ROOT_PART="$part_dev"
  elif [[ "$desc" == *"Backup"* ]]; then
    BACKUP_PART="$part_dev"
  elif [[ "$desc" == *"Media"* ]]; then
    MEDIA_PART="$part_dev"
  fi
  sgdisk -n ${num}:0:${size} -t ${num}:${code} -c ${num}:"${desc}" "$ROOT_DISK"
done <<< "$PART_LAYOUT"

# === Output ===
echo -e "\n📅 Partitioning complete."
lsblk "$ROOT_DISK"
[[ -n "${BACKUP_PART:-}" ]] && lsblk "$BACKUP_PART"
[[ -n "${MEDIA_PART:-}" ]] && lsblk "$MEDIA_PART"

# === Export variables for rest of the pipeline ===
export EFI_PART ROOT_PART BACKUP_PART FS_LAYOUT
