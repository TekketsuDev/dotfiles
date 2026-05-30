#!/usr/bin/env bash
# bootstrap.sh — one-shot setup for any machine type
# Usage: curl -sL <gitea>/raw/main/bootstrap.sh | bash
#        OR after clone: ./bootstrap.sh [--profile <name>] [--gitea <url>]
set -euo pipefail

REPO_URL="${REPO_URL:-}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
MACHINE_CONF="$DOTFILES_DIR/.machine.conf"

# --- colours ---
_g='\033[0;32m'; _y='\033[0;33m'; _r='\033[0;31m'; _b='\033[1;34m'; _n='\033[0m'
log()  { printf "${_g}[boot]${_n} %s\n" "$*"; }
warn() { printf "${_y}[warn]${_n} %s\n" "$*"; }
err()  { printf "${_r}[err] ${_n} %s\n" "$*" >&2; exit 1; }
step() { printf "\n${_b}==> %s${_n}\n" "$*"; }

# ─── parse args ──────────────────────────────────────────────────────────────
FORCE_PROFILE=""
GITEA_URL=""
SKIP_NIX=0
SKIP_STOW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) FORCE_PROFILE="$2"; shift 2 ;;
    --gitea)   GITEA_URL="$2";     shift 2 ;;
    --skip-nix)  SKIP_NIX=1;  shift ;;
    --skip-stow) SKIP_STOW=1; shift ;;
    *) warn "Unknown arg: $1"; shift ;;
  esac
done

# ─── environment detection ────────────────────────────────────────────────────
detect_profile() {
  # WSL
  if grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "wsl"; return
  fi

  # LXC container (Proxmox CT)
  if [[ -f /run/systemd/container ]] || \
     grep -qa "container=lxc" /proc/1/environ 2>/dev/null || \
     systemd-detect-virt --container 2>/dev/null | grep -q "lxc"; then
    echo "ct-minimal"; return
  fi

  local os=""
  [[ -f /etc/os-release ]] && . /etc/os-release && os="${ID:-}"

  case "$os" in
    arch)
      # Arch = assume desktop (user can override with --profile)
      echo "arch-desktop" ;;
    ubuntu|debian|linuxmint|pop)
      echo "ubuntu" ;;
    *)
      warn "Unknown OS '$os', defaulting to ubuntu profile"
      echo "ubuntu" ;;
  esac
}

detect_os_pm() {
  if grep -qi "arch" /etc/os-release 2>/dev/null; then
    echo "arch pacman"
  elif grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
    echo "apt apt"
  elif grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "wsl apt"
  else
    echo "unknown unknown"
  fi
}

# ─── check LXC Nix compatibility ─────────────────────────────────────────────
check_lxc_nix() {
  local ns_max
  ns_max=$(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo 0)
  if [[ "$ns_max" -eq 0 ]]; then
    warn "LXC: user namespaces disabled on host."
    warn "On Proxmox host run: echo 'kernel.unprivileged_userns_clone=1' >> /etc/sysctl.d/99-nix.conf && sysctl -p"
    warn "OR make the container privileged."
    warn "Falling back to system package manager only."
    return 1
  fi
  return 0
}

# ─── install nix ─────────────────────────────────────────────────────────────
install_nix() {
  if command -v nix &>/dev/null; then
    log "Nix already installed ($(nix --version))"
    return
  fi

  local profile="$1"
  step "Installing Nix"

  if [[ "$profile" == "ct-minimal" ]]; then
    check_lxc_nix || { warn "Skipping Nix install in LXC (missing user namespaces)."; return; }
  fi

  # WSL needs --no-daemon on older setups; prefer daemon where possible
  if [[ "$profile" == "wsl" ]]; then
    # Check if systemd is running in WSL
    if [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
      sh <(curl -L https://nixos.org/nix/install) --daemon
    else
      warn "WSL without systemd: using single-user Nix install"
      sh <(curl -L https://nixos.org/nix/install) --no-daemon
    fi
  else
    sh <(curl -L https://nixos.org/nix/install) --daemon
  fi

  # Source nix into current shell
  if [[ -f /etc/profile.d/nix.sh ]]; then
    # shellcheck source=/dev/null
    . /etc/profile.d/nix.sh
  elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  log "Nix installed: $(nix --version)"
}

# ─── enable flakes ────────────────────────────────────────────────────────────
enable_nix_flakes() {
  local conf="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
  mkdir -p "$(dirname "$conf")"
  if ! grep -q "experimental-features" "$conf" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "$conf"
    log "Enabled nix flakes + nix-command"
  fi
}

# ─── install home-manager ─────────────────────────────────────────────────────
install_home_manager() {
  if command -v home-manager &>/dev/null; then
    log "home-manager already installed"
    return
  fi
  step "Installing home-manager"
  nix run nixpkgs#home-manager -- --version || true
  # home-manager will be available via flake; standalone install not required
  log "home-manager available via flake"
}

# ─── apply nix profile ────────────────────────────────────────────────────────
apply_nix_profile() {
  local profile="$1"
  step "Applying Nix profile: $profile"

  export DOTFILES_USER="$(whoami)"
  export DOTFILES_HOME="$HOME"

  nix run nixpkgs#home-manager -- \
    --extra-experimental-features "nix-command flakes" \
    switch \
    --flake "$DOTFILES_DIR#$profile" \
    --impure \
    -b bak

  log "Nix profile '$profile' applied"
}

# ─── install claude code ─────────────────────────────────────────────────────
install_claude() {
  if command -v claude &>/dev/null; then
    log "Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
    return
  fi
  if ! command -v npm &>/dev/null; then
    warn "npm not found — skipping Claude Code install (run after Nix profile is active)"
    return
  fi
  step "Installing Claude Code"
  # npm global prefix must be user-writable — Nix store is read-only
  local npm_prefix="$HOME/.local/share/npm-global"
  mkdir -p "$npm_prefix"
  npm config set prefix "$npm_prefix"
  # Ensure it's on PATH
  export PATH="$npm_prefix/bin:$PATH"
  grep -qxF "export PATH=\"\$HOME/.local/share/npm-global/bin:\$PATH\"" "$HOME/.zshrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/share/npm-global/bin:$PATH"' >> "$HOME/.zshrc"
  npm install -g @anthropic-ai/claude-code
  log "Claude Code installed — restart shell or: export PATH=\"$npm_prefix/bin:\$PATH\""
}

# ─── install tmux plugin manager ─────────────────────────────────────────────
install_tpm() {
  local tpm_dir="${HOME}/.config/tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    log "TPM already installed"
    return
  fi
  step "Installing TPM (tmux plugin manager)"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  log "TPM installed — press prefix+I inside tmux to install plugins"
}

# ─── install oh-my-zsh + plugins ─────────────────────────────────────────────
install_omz() {
  local omz_dir="${HOME}/.config/.oh-my-zsh"
  local custom_dir="${omz_dir}/custom/plugins"

  if [[ -d "$omz_dir" ]]; then
    log "oh-my-zsh already installed at $omz_dir"
  else
    step "Installing oh-my-zsh"
    local omz_install
    omz_install="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_install"
    ZSH="$omz_dir" RUNZSH=no CHSH=no bash "$omz_install" --unattended --keep-zshrc
    rm -f "$omz_install"
    log "oh-my-zsh installed"
  fi

  # tmux-resurrect + tmux-continuum
  local tpm_plugins="${HOME}/.config/tmux/plugins"
  for plugin in tmux-resurrect tmux-continuum; do
    if [[ ! -d "$tpm_plugins/$plugin" ]]; then
      log "Installing tmux plugin: $plugin"
      git clone --depth=1 "https://github.com/tmux-plugins/$plugin" "$tpm_plugins/$plugin"
    fi
  done

  # zsh-autosuggestions
  if [[ ! -d "$custom_dir/zsh-autosuggestions" ]]; then
    log "Installing zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
  fi

  # zsh-syntax-highlighting
  if [[ ! -d "$custom_dir/zsh-syntax-highlighting" ]]; then
    log "Installing zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"
  fi
}

# ─── set default shell to zsh ────────────────────────────────────────────────
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null || true)"
  if [[ -z "$zsh_path" ]]; then
    warn "zsh not found, skipping shell change"
    return
  fi
  if [[ "$SHELL" == "$zsh_path" ]]; then
    log "Default shell already zsh"
    return
  fi
  # Ensure zsh is in /etc/shells
  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  step "Setting default shell to zsh"
  sudo chsh -s "$zsh_path" "$(whoami)"
  log "Default shell set to $zsh_path — open a new terminal to apply"
}

# ─── stow configs ─────────────────────────────────────────────────────────────
apply_stow() {
  step "Applying stow configs"
  if ! command -v stow &>/dev/null; then
    warn "stow not found yet — will be available after Nix profile apply. Re-run 'dev apply' after shell reload."
    return
  fi
  bash "$DOTFILES_DIR/dev.sh" apply
  log "Stow configs applied"
}

# ─── install system deps (pre-nix bootstrap deps) ────────────────────────────
install_bootstrap_deps() {
  local pm="$1"
  step "Installing bootstrap dependencies (git, curl, stow)"

  case "$pm" in
    pacman)
      sudo pacman -Sy --noconfirm --needed git curl stow ;;
    apt)
      sudo apt-get update -q && sudo apt-get install -y git curl stow ;;
    *)
      warn "Unknown package manager '$pm', skipping bootstrap deps" ;;
  esac
}

# ─── clone repo if not present ────────────────────────────────────────────────
ensure_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Dotfiles repo already at $DOTFILES_DIR"
    return
  fi
  if [[ -z "$REPO_URL" ]]; then
    err "REPO_URL not set and $DOTFILES_DIR is not a git repo. Set REPO_URL=git@gitea:tekketsu/dotfiles or REPO_URL=https://github.com/..."
  fi
  step "Cloning dotfiles"
  git clone "$REPO_URL" "$DOTFILES_DIR"
}

# ─── write machine config ─────────────────────────────────────────────────────
write_machine_conf() {
  local profile="$1"
  cat > "$MACHINE_CONF" <<EOF
# Auto-generated by bootstrap.sh — machine-specific, not committed
DOTFILES_PROFILE=$profile
DOTFILES_MACHINE=$(hostname)
DOTFILES_USER=$(whoami)
DOTFILES_HOME=$HOME
EOF
  if [[ -n "$GITEA_URL" ]]; then
    echo "GITEA_REMOTE_URL=$GITEA_URL" >> "$MACHINE_CONF"
    # Add gitea remote
    if ! git -C "$DOTFILES_DIR" remote | grep -q "gitea"; then
      git -C "$DOTFILES_DIR" remote add gitea "$GITEA_URL"
      log "Gitea remote added: $GITEA_URL"
    fi
  fi
  log "Machine config written to $MACHINE_CONF"
}

# ─── setup dev launcher ───────────────────────────────────────────────────────
setup_dev_launcher() {
  step "Setting up 'dev' launcher"
  bash "$DOTFILES_DIR/dev.sh" install
}

# ─── main ─────────────────────────────────────────────────────────────────────
main() {
  log "Bootstrap starting on $(hostname) as $(whoami)"

  # Detect environment
  local profile="${FORCE_PROFILE:-$(detect_profile)}"
  read -r _os pm <<< "$(detect_os_pm)"
  log "Detected profile: $profile | OS pm: $pm"

  # If machine.conf exists, prefer saved profile unless overridden
  if [[ -z "$FORCE_PROFILE" && -f "$MACHINE_CONF" ]]; then
    # shellcheck source=/dev/null
    . "$MACHINE_CONF"
    profile="${DOTFILES_PROFILE:-$profile}"
    log "Loaded existing machine config: profile=$profile"
  fi

  install_bootstrap_deps "$pm"
  ensure_repo
  write_machine_conf "$profile"
  setup_dev_launcher

  if [[ "$SKIP_NIX" -eq 0 ]]; then
    install_nix "$profile"
    enable_nix_flakes
    install_home_manager
    apply_nix_profile "$profile"
  else
    warn "Skipping Nix install (--skip-nix)"
  fi

  set_default_shell
  install_omz
  install_tpm
  install_claude

  if [[ "$SKIP_STOW" -eq 0 ]]; then
    apply_stow
  fi

  step "Bootstrap complete"
  log "Profile : $profile"
  log "Dotfiles: $DOTFILES_DIR"
  log ""
  log "Next steps:"
  log "  1. Open a new shell (or: source ~/.zshrc)"
  log "  2. Run 'dev apply' to re-apply configs"
  log "  3. Run 'dev gitea-push' to sync to Gitea"
}

main "$@"
