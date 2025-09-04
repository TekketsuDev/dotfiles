#!/usr/bin/env bash
set -euo pipefail

declare -A LAYOUTS
LAYOUTS["default"]=$'1|+512M|ef00|EFI_System_Partition\n3|rest|8309|Linux_Root_x86-64'
LAYOUTS["btrfs_example"]=$'1|+1G|ef00|EFI_System_Partition\n2|rest|8300|BTRFS_Main_Pool\n<SUBVOL>@|Root_FS|/\n<SUBVOL>@home|User_Homes|/home\n<SUBVOL>@snapshots|System_Snapshots|/.snapshots\n<SUBVOL>@log|Log_Files|/var/log\n<SUBVOL>@data|Media_Files|/data\n<SUBVOL>@vm|Virtual_Machines|/vm'
LAYOUTS["root+backup"]=$'1|+512M|ef00|EFI_System_Partition\n3|+100G|8309|Linux_Root_x86-64\n4|rest|8300|Linux_Backup'

declare -A LAYOUTS
LAYOUTS["default"]=$'
1|+512M|ef00|EFI_System_Partition
\n3|rest|8309|Linux_Root_(x86-64)'

LAYOUTS["btrfs_example"]=$'1|+1G|ef00|EFI_System_Partition
\n2|rest|8300|BTRFS_Pool\n
<SUBVOL>@|Root_Filesystem|/\n
<SUBVOL>@home|User_Home|/home\n
<SUBVOL>@snapshots|System_Snapshots|/.snapshots\n
<SUBVOL>@log|Log_Files|/var/log\n
<SUBVOL>@data|Media_Files|/data\n
<SUBVOL>@vm|Virtual_Machines|/vm'

LAYOUTS["root+backup"]=$'1|+512M|ef00|EFI_System_Partition\n
2|+100G|8309|Linux_Root_(x86-64)\n
3|rest|8300|Linux_Backup'

get_single_layout_preview_lines() {
    local -n _output_array_ref=$1
    local layout_name="$2"
    _output_array_ref=()
    if [[ -z "${LAYOUTS[$layout_name]+isset}" ]]; then
        _output_array_ref+=("Error: Layout '$layout_name' not defined.")
        return 1
    fi
    local layout_definition_string="${LAYOUTS[$layout_name]}"
    local -a content_lines
    content_lines+=("🔧 Layout: $layout_name")
    content_lines+=("$(printf "%-4s %-10s %-6s %-30s" "Num" "Size" "Code" "Description (Physical Partitions)")")
    content_lines+=("$(printf "%-4s %-10s %-6s %-30s" "----" "----------" "------" "------------------------------")")
    local -a physical_partition_lines_buffer=()
    local -a subvolume_definition_lines_buffer=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == "<SUBVOL>"* ]]; then subvolume_definition_lines_buffer+=("$line"); else physical_partition_lines_buffer+=("$line"); fi
    done <<< "$layout_definition_string"
    for part_line in "${physical_partition_lines_buffer[@]}"; do
        IFS="|" read -r actual_num size code desc <<< "$part_line"; content_lines+=("$(printf "%-4s %-10s %-6s %-30s" "$actual_num" "$size" "$code" "$desc")"); done

    if [[ ${#subvolume_definition_lines_buffer[@]} -gt 0 ]]; then
        content_lines+=("")
        content_lines+=("$(printf "%-4s %-12s %-20s %-15s" "" "Subvolume" "Purpose" "Mount Point")")
        content_lines+=("$(printf "%-4s %-12s %-20s %-15s" "" "-----------" "--------------------" "---------------")")
        for subvol_def_line in "${subvolume_definition_lines_buffer[@]}"; do
            local clean_line_data="${subvol_def_line#<SUBVOL>}"
            IFS="|" read -r subvol_name subvol_purpose subvol_mount_point <<< "$clean_line_data"
            content_lines+=("$(printf "%-4s %-12s %-20s %-15s" "" "$subvol_name" "$subvol_purpose" "$subvol_mount_point")")
        done
    fi
    local max_content_width_this_layout=0; for line_content_for_width in "${content_lines[@]}"; do if (( ${#line_content_for_width} > max_content_width_this_layout )); then max_content_width_this_layout=${#line_content_for_width}; fi; done
    local min_known_width=53; if [[ ${#subvolume_definition_lines_buffer[@]} -gt 0 ]]; then min_known_width=54; fi; if (( max_content_width_this_layout < min_known_width )); then max_content_width_this_layout=$min_known_width; fi
    local box_top_left="┌" box_top_right="┐" box_bottom_left="└" box_bottom_right="┘"; local box_horizontal="─" box_vertical="│" padding_char=" "; local border_segment=""; for ((k=0; k < max_content_width_this_layout + 2; k++)); do border_segment+="$box_horizontal"; done
    _output_array_ref+=("$box_top_left$border_segment$box_top_right"); for line_content in "${content_lines[@]}"; do local padded_content; padded_content=$(printf "%-${max_content_width_this_layout}s" "$line_content"); if [[ "$line_content" == "🔧 Layout:"* ]]; then padded_content+=" "; fi; _output_array_ref+=("$box_vertical$padding_char$padded_content$padding_char$box_vertical"); done; _output_array_ref+=("$box_bottom_left$border_segment$box_bottom_right"); return 0
}

mapfile -t layout_option_keys < <(printf "%s\n" "${!LAYOUTS[@]}" | sort)
if [[ ${#layout_option_keys[@]} -eq 0 ]]; then echo "No layouts defined." >&2; exit 1; fi
first_layout_to_print=true
for layout_key_to_display in "${layout_option_keys[@]}"; do
    if ! $first_layout_to_print; then echo; fi; first_layout_to_print=false
    declare -a boxed_layout_lines_array
    if get_single_layout_preview_lines boxed_layout_lines_array "$layout_key_to_display"; then
        for line in "${boxed_layout_lines_array[@]}"; do printf "%s\n" "$line"; done
    else
        for line in "${boxed_layout_lines_array[@]}"; do printf "%s\n" "$line" >&2; done
    fi
done
echo

SELECTED_LAYOUT_KEY=""
echo "--- Layout Selection ---"
PS3="👉 Choose a layout number: "
select selected_layout_name_from_menu in "${layout_option_keys[@]}"; do
    if [[ -n "$selected_layout_name_from_menu" ]]; then
        SELECTED_LAYOUT_KEY="$selected_layout_name_from_menu"
        echo "✅ Selected layout: $SELECTED_LAYOUT_KEY"
        break
    else
        echo "❌ Invalid selection. Please try again." >&2
    fi
done

if [[ -z "$SELECTED_LAYOUT_KEY" ]]; then echo "No layout selected. Exiting." >&2; exit 1; fi

chosen_layout_definition_string="${LAYOUTS[$SELECTED_LAYOUT_KEY]}"
declare -a physical_partitions_list_for_export=()
declare -a btrfs_subvolume_names_list=()
declare -a btrfs_subvolume_purposes_list=()
declare -a btrfs_subvolume_mounts_list=()
IMPLIED_FS_LAYOUT="ext4"

if grep -q "BTRFS Main Pool" <<< "$chosen_layout_definition_string" || grep -q "<SUBVOL>" <<< "$chosen_layout_definition_string"; then
    IMPLIED_FS_LAYOUT="btrfs"
fi

while IFS= read -r line_from_def; do
    [[ -z "$line_from_def" ]] && continue
    if [[ "$line_from_def" == "<SUBVOL>"* ]]; then
        clean_subvol_data="${line_from_def#<SUBVOL>}"
        IFS="|" read -r subvol_name subvol_purpose subvol_mount <<< "$clean_subvol_data"
        btrfs_subvolume_names_list+=("$subvol_name")
        btrfs_subvolume_purposes_list+=("$subvol_purpose")
        btrfs_subvolume_mounts_list+=("$subvol_mount")
    else
        physical_partitions_list_for_export+=("$line_from_def")
    fi
done <<< "$chosen_layout_definition_string"

EXPORTED_PHYSICAL_PARTITIONS_DEF=$(printf "%s\n" "${physical_partitions_list_for_export[@]}")
EXPORTED_PHYSICAL_PARTITIONS_DEF="${EXPORTED_PHYSICAL_PARTITIONS_DEF%$'\n'}"

EXPORTED_BTRFS_SUBVOLUME_NAMES=$(printf "%s\n" "${btrfs_subvolume_names_list[@]}")
EXPORTED_BTRFS_SUBVOLUME_NAMES="${EXPORTED_BTRFS_SUBVOLUME_NAMES%$'\n'}"

EXPORTED_BTRFS_SUBVOLUME_PURPOSES=$(printf "%s\n" "${btrfs_subvolume_purposes_list[@]}")
EXPORTED_BTRFS_SUBVOLUME_PURPOSES="${EXPORTED_BTRFS_SUBVOLUME_PURPOSES%$'\n'}"

EXPORTED_BTRFS_SUBVOLUME_MOUNTS=$(printf "%s\n" "${btrfs_subvolume_mounts_list[@]}")
EXPORTED_BTRFS_SUBVOLUME_MOUNTS="${EXPORTED_BTRFS_SUBVOLUME_MOUNTS%$'\n'}"

export SELECTED_LAYOUT_KEY
export SELECTED_FS_LAYOUT="$IMPLIED_FS_LAYOUT"
export EXPORTED_PHYSICAL_PARTITIONS_DEF
export EXPORTED_BTRFS_SUBVOLUME_NAMES
export EXPORTED_BTRFS_SUBVOLUME_PURPOSES
export EXPORTED_BTRFS_SUBVOLUME_MOUNTS

echo "--- Layout Definitions Exported ---"
echo "SELECTED_LAYOUT_KEY=$SELECTED_LAYOUT_KEY"
echo "SELECTED_FS_LAYOUT=$SELECTED_FS_LAYOUT"

echo $EXPORTED_PHYSICAL_PARTITIONS_DEF
echo $EXPORTED_BTRFS_SUBVOLUME_NAMES
echo $EXPORTED_BTRFS_SUBVOLUME_PURPOSES
echo $EXPORTED_BTRFS_SUBVOLUME_MOUNTS
