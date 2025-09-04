#!/usr/bin/env bash

set -euo pipefail

#FILE="$1"
#ROLE="$2"
# --- 🧠 System Identity ---
HOSTNAME=$(cat /etc/hostname)
USER=$(whoami)
GROUP=$(id -gn)
IP=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')

echo "🖥️  Hostname : $HOSTNAME"
echo "👤 User     : $USER"
echo "👥 Group    : $GROUP"
echo "🌐 IP       : $IP"

# -- Internal State
_DETECTED=0

function detect_os_pm() {
    if grep -qi "arch" /etc/os-release; then
        OS="arch"
        PKG_MGR="pacman"
    elif grep -qi "ubuntu" /etc/os-release; then
        OS="ubuntu"
        PKG_MGR="apt"
    elif grep -qi "debian" /etc/os-release; then
        OS="debian"
        PKG_MGR="apt"
    elif grep -qi "microsoft" /proc/version 2>/dev/null; then
        OS="wsl"
        PKG_MGR="apt"
    else
        echo "Unsupported OS"
        exit 1
    fi

    _DETECTED=1
}

function fallback_pm() {
  local pkg="$1"

  case "$PKG_MGR" in
    pacman)
      if ! sudo pacman -S --noconfirm --needed "$pkg"; then
        if command -v yay &>/dev/null; then
        yay -S --noconfirm "$pkg"
      else
        return 1
        fi
      fi
      ;;
    apt) 
      if ! sudo apt install -y "$pkg"; then
        if command -v snap &>/dev/null; then
          sudo snap &>/dev/null || true
        elif command -v flatpak &>/dev/null; then
          flatpak install -y "$pkg" || true
        fi
      fi  
    esac
}

install_pkg_list() {
    local list_file="$1"

    [[ $_DETECTED -eq 0 ]] && detect_os_and_package_manager

    if [[ ! -f "$list_file" ]]; then
        echo "❌ Package list file not found: $list_file"
        return 1
    fi

    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        _install_one_pkg "$pkg"
    done < "$list_file"
}

detect_os_pm

install_pkg() {
    [[ $_DETECTED -eq 0 ]] && detect_os_pm
    fallback_pm "$1"
}

