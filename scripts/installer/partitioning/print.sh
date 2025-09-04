#!/usr/bin/env bash

show_layout_preview() {
    local layout_name="$1"
    local layout="${LAYOUTS[$layout_name]}"

    echo -e "\n🔧 Layout: $layout_name"
    printf "%-3s %-10s %-6s %-30s\n" "No" "Size" "Code" "Description"
    printf "%-3s %-10s %-6s %-30s\n" "---" "--------" "------" "------------------------------"

    while IFS= read -r line; do
        IFS="|" read -r num size code desc <<< "$line"
        printf "%-3s %-10s %-6s %-30s\n" "$num" "$size" "$code" "$desc"
    done <<< "$layout"
}

# Declare layouts
declare -A LAYOUTS

LAYOUTS["default"]=$'1|+512M|ef00|EFI\n3|rest|8309|Root'
LAYOUTS["dualboot"]=$'1|+512M|ef00|EFI\n2|+4M|ef02|BIOS Boot\n3|rest|8309|Root'
LAYOUTS["root+backup"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8300|Backup'
LAYOUTS["separate_home"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8302|Home'
LAYOUTS["root+media"]=$'1|+512M|ef00|EFI\n3|+100G|8309|Root\n4|rest|8301|Media'

show_layout_preview() {
    local layout_name="$1"
    local layout="${LAYOUTS[$layout_name]}"

    echo -e "\n🔧 Layout: $layout_name"
    printf "%-3s %-10s %-6s %-30s\n" "No" "Size" "Code" "Description"
    printf "%-3s %-10s %-6s %-30s\n" "---" "--------" "------" "------------------------------"

    while IFS= read -r line; do
        IFS="|" read -r num size code desc <<< "$line"
        printf "%-3s %-10s %-6s %-30s\n" "$num" "$size" "$code" "$desc"
    done <<< "$layout"
}

echo -e "\n📀 Available partition layouts:"
select LAYOUT_KEY in "${!LAYOUTS[@]}"; do
    [[ -n "$LAYOUT_KEY" ]] && break
    echo "❌ Invalid selection. Please try again."
done

show_layout_preview "$LAYOUT_KEY"

