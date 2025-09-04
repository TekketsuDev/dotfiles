#!/usr/bin/env bash

set -euo pipefail

# --- Assume these are already set from previous steps ---
# Example LAYOUTS definition (ensure your actual one is used)
declare -A LAYOUTS
LAYOUTS["default"]=$'1|+512M|ef00|EFI System Partition\n3|rest|8309|Linux Root (x86-64)'
LAYOUTS["btrfs_example"]=$'1|+1G|ef00|EFI System Partition\n2|rest|8300|BTRFS Main Pool\n<SUBVOL>@|Root FS (/)\n<SUBVOL>@home|User Homes (/home)\n<SUBVOL>@snapshots|System Snapshots\n<SUBVOL>@log|Log Files (/var/log)\n<SUBVOL>@data|Media Files(/data)\n<SUBVOL>@vm|Virtual Machines (/vm)'
LAYOUTS["root+backup"]=$'1|+512M|ef00|EFI System Partition\n3|+100G|8309|Linux Root (x86-64)\n4|rest|8300|Linux Backup'

# User's choices from previous steps (replace with your actual variables)
LAYOUT_KEY="btrfs_example" # Example: User chose this
ROOT_DISK="/dev/sdb"       # Example: User chose this disk
FS_LAYOUT="btrfs"          # Example: User chose BTRFS

echo "Processing layout '$LAYOUT_KEY' for disk '$ROOT_DISK' with filesystem '$FS_LAYOUT'"

# --- Get the chosen layout string ---
if [[ -z "${LAYOUTS[$LAYOUT_KEY]+isset}" ]]; then
    echo "Error: Layout '$LAYOUT_KEY' is not defined." >&2
    exit 1
fi
chosen_layout_string="${LAYOUTS[$LAYOUT_KEY]}"

# --- Arrays to store parsed information ---
declare -a physical_partitions_for_sgdisk=()
declare -a btrfs_subvolumes_to_create=()
declare -a btrfs_subvolume_mounts=() # To store intended mount points

# --- Variables to identify key partitions ---
EFI_PART_DEVICE=""
BTRFS_POOL_PART_DEVICE="" # The physical partition that will become the BTRFS pool

# Determine partition device prefix (e.g., /dev/sda1 vs /dev/nvme0n1p1)
if [[ "$ROOT_DISK" == *nvme* ]]; then
    part_prefix="${ROOT_DISK}p"
else
    part_prefix="${ROOT_DISK}"
fi

echo "--- Parsing Layout Definition ---"
while IFS= read -r line; do
    [[ -z "$line" ]] && continue # Skip empty lines

    if [[ "$line" == "<SUBVOL>"* ]]; then
        # This is a BTRFS subvolume definition
        clean_line_data="${line#<SUBVOL>}" # Remove the <SUBVOL> prefix
        IFS="|" read -r subvolume_name subvolume_description_and_mount <<< "$clean_line_data"

        btrfs_subvolumes_to_create+=("$subvolume_name")
        btrfs_subvolume_mounts+=("$subvolume_description_and_mount") # Storing the full desc for now
        echo "  Found BTRFS Subvolume: Name='$subvolume_name', Purpose='$subvolume_description_and_mount'"
    else
        # This is a physical partition definition
        IFS="|" read -r num size code desc <<< "$line"
        part_device_name="${part_prefix}${num}" # e.g., /dev/sda1 or /dev/nvme0n1p1

        # Store the command parts for sgdisk
        # Format: "number:start_offset:end_offset_or_size typecode name"
        # We use 0 for start_offset to let sgdisk place it optimally after the previous one.
        physical_partitions_for_sgdisk+=("${num}:0:${size} ${code} ${desc}")
        echo "  Found Physical Partition: Num=$num, Size=$size, Code=$code, Desc='$desc' (Device: $part_device_name)"

        # Identify key partitions based on description
        if [[ "$desc" == *"EFI System Partition"* ]]; then
            EFI_PART_DEVICE="$part_device_name"
        elif [[ "$desc" == *"BTRFS Main Pool"* ]] || [[ "$desc" == *"BTRFS Linux System"* ]]; then
            # Assuming this is the partition to format as BTRFS
            BTRFS_POOL_PART_DEVICE="$part_device_name"
        fi
    fi
done <<< "$chosen_layout_string"

echo # Blank line

# --- Phase 1: Create Physical Partitions with sgdisk ---
echo "--- Phase 1: Creating Physical Partitions on $ROOT_DISK ---"
# First, wipe the existing partition table (ensure user has confirmed this already!)
echo "Wiping existing partition table on $ROOT_DISK (sgdisk --zap-all)..."
sgdisk --zap-all "$ROOT_DISK" # Add error handling if needed

for sgdisk_params in "${physical_partitions_for_sgdisk[@]}"; do
    # sgdisk_params is like "1:0:+512M ef00 EFI System Partition"
    # We need to separate the name part for the -c option
    read -r part_num_size_type part_name <<< "$(echo "$sgdisk_params" | awk '{name_start=NF; for (i=3; i<=NF; i++) name_start=i; printf "%s %s ", $1, $2; for (i=3; i<=NF; i++) printf "%s ", $i; printf "\n"}')"

    # A simpler way if name doesn't have spaces, or if we use the full string for name
    # For sgdisk, it's --new=partnum:start:end --typecode=partnum:type --change-name=partnum:"Name"

    # Let's re-parse from sgdisk_params for clarity
    # Example: "1:0:+512M ef00 EFI System Partition"
    part_num_and_size_spec=$(echo "$sgdisk_params" | awk '{print $1}') # e.g., 1:0:+512M
    part_typecode=$(echo "$sgdisk_params" | awk '{print $2}')          # e.g., ef00
    part_name_desc=$(echo "$sgdisk_params" | cut -d' ' -f3-)         # e.g., EFI System Partition

    part_num=$(echo "$part_num_and_size_spec" | cut -d':' -f1)

    echo "Executing: sgdisk --new=${part_num_and_size_spec} --typecode=${part_num}:${part_typecode} --change-name=${part_num}:\"${part_name_desc}\" \"$ROOT_DISK\""
    sgdisk --new="${part_num_and_size_spec}" --typecode="${part_num}:${part_typecode}" --change-name="${part_num}:${part_name_desc}" "$ROOT_DISK"
    # Add error checking for sgdisk if desired
done

echo "Physical partitioning complete. Waiting for kernel to update..."
sync
sleep 2
partprobe "$ROOT_DISK" || echo "Warning: partprobe failed or not found."
sleep 1

echo "Current partition layout on $ROOT_DISK:"
lsblk -p "$ROOT_DISK"

echo # Blank line
echo "Identified EFI Partition: ${EFI_PART_DEVICE:-Not Set}"
echo "Identified BTRFS Pool Partition: ${BTRFS_POOL_PART_DEVICE:-Not Set}"
echo # Blank line

# --- Phase 2: Format Partitions (Example for BTRFS) ---
# This phase would be in your *next* script (e.g., format_and_mount.sh)
# But for demonstration, here's how you'd use the identified BTRFS_POOL_PART_DEVICE

if [[ "$FS_LAYOUT" == "btrfs" ]] && [[ -n "$BTRFS_POOL_PART_DEVICE" ]]; then
    echo "--- Phase 2 (Conceptual): Formatting BTRFS Pool ---"
    echo "Formatting $BTRFS_POOL_PART_DEVICE as BTRFS..."
    # mkfs.btrfs -f "$BTRFS_POOL_PART_DEVICE" # The -f forces if already formatted
    echo "Command: mkfs.btrfs -f \"$BTRFS_POOL_PART_DEVICE\" (Example, not run here)"

    # Mount the BTRFS pool to a temporary location to create subvolumes
    TEMP_BTRFS_MOUNT="/mnt/btrfs_temp_root"
    echo "Creating temporary mount point: $TEMP_BTRFS_MOUNT"
    # mkdir -p "$TEMP_BTRFS_MOUNT"
    echo "Mounting BTRFS pool: mount \"$BTRFS_POOL_PART_DEVICE\" \"$TEMP_BTRFS_MOUNT\" (Example, not run here)"
    # mount "$BTRFS_POOL_PART_DEVICE" "$TEMP_BTRFS_MOUNT"

    echo # Blank line
    echo "--- Phase 3 (Conceptual): Creating BTRFS Subvolumes ---"
    if [[ ${#btrfs_subvolumes_to_create[@]} -gt 0 ]]; then
        echo "Identified BTRFS subvolumes to create:"
        for i in "${!btrfs_subvolumes_to_create[@]}"; do
            subvol_name="${btrfs_subvolumes_to_create[i]}"
            subvol_mount_info="${btrfs_subvolume_mounts[i]}" # This is "Description (Mount Point)"

            echo "  Subvolume Name: $subvol_name (Purpose: $subvol_mount_info)"
            echo "  Command: btrfs subvolume create \"${TEMP_BTRFS_MOUNT}/${subvol_name}\" (Example, not run here)"
        done
    else
        echo "No BTRFS subvolumes defined in this layout."
    fi

    echo "Unmounting BTRFS pool: umount \"$TEMP_BTRFS_MOUNT\" (Example, not run here)"
    # umount "$TEMP_BTRFS_MOUNT"
    # rmdir "$TEMP_BTRFS_MOUNT"
else
    echo "Filesystem is not BTRFS or BTRFS pool partition not identified. Skipping BTRFS setup."
fi

echo # Blank line
echo "--- End of Extraction and Conceptual Next Steps ---"
echo "The next script would handle actual formatting, subvolume creation, and mounting."
