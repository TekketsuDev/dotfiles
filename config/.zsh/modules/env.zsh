# ================================
# ~/.zsh/modules/env.zsh
# ================================

# Core Paths
export DOTFILES="$HOME/dotfiles"
export DOTFILES_CONFIG="$DOTFILES/config"
export DOTFILES_SCRIPTS="$DOTFILES/scripts"
export DOTFILES_INSTALLER_PATH="$DOTFILES/scripts/installer/base/"
export CONFIG_HOME="$HOME/.config"
export LOCAL_HOME="$HOME/.local"
export PACKAGE_CORE="$HOME/dotfiles/scripts/installer/packages/package_core.sh"

# XDG Base Directories
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$LOCAL_HOME/share"
export XDG_CACHE_HOME="$LOCAL_HOME/cache"
export XDG_STATE_HOME="$LOCAL_HOME/state"

# Programming Languages
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk/"
export RUST_ENV_PATH="$HOME/.cargo/env"
export LIBCLANG_PATH="/usr/lib/llvm-19/lib"

# Hyprland tools
export HYPRLAND_CONFIG_PATH="$CONFIG_HOME/hyper/hyprland.conf"
export WAYLAND_DISPLAY="wayland-1"
# Common tools
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export SYSTEM_EDITOR="nvim"
# Locale
#export LANG="en_US.UTF-8"
#export LC_ALL="en_US.UTF-8"

# Apps
export ZATHURA_PLUGINS_PATH="/usr/lib/zathura"
export BROWSER="brave"
#export GTK_THEME="Catppuccin-Mocha-Standard-Blue-Dark"
export OBSIDIAN="$HOME/Notes"
export ATTACHMENTS="$OBSIDIAN/Brain/Data/Attachments"
export KEYMAPP_SOCKET="$XDG_CONFIG_HOME/keymapp/keymapp.sock"
export PATH="$HOME/projects/kontroll/target/release:$PATH"
# Custom bin paths
export PATH="$HOME/bin:$LOCAL_HOME/bin:$PATH"
export USER="vjamet-s"
export MAIL="vjamet-s@student.42barcelona.com"
