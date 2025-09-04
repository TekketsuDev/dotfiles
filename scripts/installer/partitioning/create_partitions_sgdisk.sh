#umount -R /mnt || true
for p in /dev/sda?*; do
  umount "$p" 2>/dev/null || true
done
!/usr/bin/env bash
set -euo pipefail

TARGET_DEVICE_PATH="$1"
PARTITIONS_DEF_STRING="$2"

if [[ -z "$TARGET_DEVICE_PATH" ]] || [[ -z "$PARTITIONS_DEF_STRING" ]]; then
    echo "Usage: source create_partitions_sgdisk.sh <full_disk_device_path> <partitions_definition_string>" >&2
    return 1
fi

echo "--- Creating Physical Partitions on $TARGET_DEVICE_PATH ---"
sgdisk --zap-all "$TARGET_DEVICE_PATH"

part_prefix=""
if [[ "$TARGET_DEVICE_PATH" == *nvme* ]]; then
    part_prefix="${TARGET_DEVICE_PATH}p"
else
    part_prefix="${TARGET_DEVICE_PATH}"
fi

EFI_PART_DEVICE=""
ROOT_PART_DEVICE=""
BACKUP_PART_DEVICE=""
# Puedes añadir más variables aquí si tienes otros roles de partición, ej: MEDIA_PART_DEVICE

while IFS= read -r def_line; do
    [[ -z "$def_line" ]] && continue
    IFS="|" read -r pnum psize pcode pname <<< "$def_line"

    sgdisk_end_sector_or_size_param="$psize"
    if [[ "$psize" == "rest" ]]; then
        sgdisk_end_sector_or_size_param="0"
    fi

    echo "Creating partition $pnum on $TARGET_DEVICE_PATH: Name=\"$pname\", SizeSpec=\"$psize\" (sgdisk end/size: $sgdisk_end_sector_or_size_param), Type=$pcode"
    sgdisk --new="${pnum}:0:${sgdisk_end_sector_or_size_param}" --typecode="${pnum}:${pcode}" --change-name="${pnum}:${pname}" "$TARGET_DEVICE_PATH"

    current_part_device="${part_prefix}${pnum}"

    # Asegúrate de que los nombres en estas condiciones coincidan EXACTAMENTE
    # con los nombres que usas en las definiciones de LAYOUTS en box.sh
    if [[ "$pname" == "EFI_System_Partition" ]]; then
        EFI_PART_DEVICE="$current_part_device"
    elif [[ "$pname" == "Linux_Root_x86-64" ]] || \
         [[ "$pname" == "BTRFS_Main_Pool" ]] || \
         [[ "$pname" == "BTRFS_Pool" ]] || \
         [[ "$pname" == "Linux_Root_/"* ]] || \
         [[ "$pname" == "BTRFS_Linux_System" ]]; then
        ROOT_PART_DEVICE="$current_part_device"
    elif [[ "$pname" == "Linux_Backup" ]]; then
        BACKUP_PART_DEVICE="$current_part_device"
    # Ejemplo para una partición de media:
    # elif [[ "$pname" == "Linux_Media_Data" ]]; then
    #     MEDIA_PART_DEVICE="$current_part_device"
    fi
done <<< "$PARTITIONS_DEF_STRING"

echo "Physical partitioning complete. Informing kernel..."
sync
partprobe "$TARGET_DEVICE_PATH" || echo "Warning: partprobe failed or not found." >&2
sleep 1

export EFI_PART_DEVICE
export ROOT_PART_DEVICE
export BACKUP_PART_DEVICE
# export MEDIA_PART_DEVICE # Si la añades

echo "--- Actual Partition Device Paths Exported ---"
echo "EFI_PART_DEVICE=${EFI_PART_DEVICE:-UNSET}"
echo "ROOT_PART_DEVICE=${ROOT_PART_DEVICE:-UNSET}"
echo "BACKUP_PART_DEVICE=${BACKUP_PART_DEVICE:-UNSET_OR_NONE}"
# echo "MEDIA_PART_DEVICE=${MEDIA_PART_DEVICE:-UNSET_OR_NONE}" # Si la añades
