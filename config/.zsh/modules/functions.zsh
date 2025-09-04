# ================================
# ~/.zsh/modules/functions.zsh
# ================================
portInfo() {
  if [ -z "$1" ]; then
    echo "Usage: portInfo <port>"
    return 1
  fi

  echo "🔎 Checking info for port $1..."
  sudo lsof -i :$1 -nP
}

portFancy(){
  if [ -z "$1" ]; then
    echo "Usage: portFancy <port>"
    return 1
  fi
  PID=$(sudo lsof -ti :$1)
  CONFIG_FILE="$HOME/.config/btop/btop.conf"
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️ btop config not found. Run btop once to generate it."
    return 1
  fi
  echo "✅ PID using port $1: $PID"
  echo "⚙️  Pre-filtering btop by PID..."
  sed -i "s/^proc_filter.*/proc_filter=\"$PID\"/" "$CONFIG_FILE"
  sed -i "s/^proc_sorting.*/proc_sorting=\"pid\"/" "$CONFIG_FILE"
  btop
}

# ================================
# ~/.zsh/modules/navigation.zsh
# ================================

chpwd() {
  local current_date=$(date "+%Y-%m-%d %H:%M:%S")
  local folder_permissions=$(stat -c "%A" "$PWD")
  local user=$(id -u -n)
  local group=$(id -g -n)
  local pid=$$
}

goto() {
  case $1 in
    dotfiles) cd ~/dotfiles ;;
    obsidian) cd ~/dotfiles/obsidian ;;
    hypr) cd ~/dotfiles/.config/hypr ;;
    *) echo "Unknown location: $1" ;;
  esac
}

# ================================
# ~/.zsh/modules/zoxide.zsh
# ================================
eval "$(zoxide init zsh)"

# Auto `ls` after jumping
z() {
  __zoxide_z "$@" && eza -al --icons --color=always
}

zn() {
  __zoxide_z "$@" && nvim .
}
