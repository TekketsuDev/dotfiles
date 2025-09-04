#!/bin/bash
echo "🔍 Scanning for files not owned by any package..."

EXCLUDED=(
    "/proc"
    "/dev"
    "/sys"
    "/run"
    "/tmp"
    "/var/tmp"
    "/home"
    "/mnt"
    "/media"
)

should_skip() {
    for path in "${EXCLUDED[@]}"; do
        [[ "$1" == "$path"* ]] && return 0
    done
    return 1
}

find / -type f 2>/dev/null | while read -r file; do
    if should_skip "$file"; then
        continue
    fi
    if ! pacman -Qo "$file" &>/dev/null; then
        echo "⚠️  Untracked: $file"
    fi
done

