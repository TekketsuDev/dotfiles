#!/usr/bin/env bash
# setup-gitea-remote.sh — configure Gitea as the primary remote for dotfiles
# Usage: ./scripts/gitea/setup-gitea-remote.sh <gitea-host> [repo-path]
#
# Example:
#   ./scripts/gitea/setup-gitea-remote.sh git@192.168.1.10:tekketsu/dotfiles.git
#   ./scripts/gitea/setup-gitea-remote.sh https://gitea.lan tekketsu/dotfiles
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MACHINE_CONF="$REPO_ROOT/.machine.conf"

_g='\033[0;32m'; _y='\033[0;33m'; _r='\033[0;31m'; _n='\033[0m'
log()  { printf "${_g}[gitea]${_n} %s\n" "$*"; }
warn() { printf "${_y}[warn]${_n} %s\n" "$*"; }
err()  { printf "${_r}[err]${_n} %s\n" "$*" >&2; exit 1; }

# ─── parse args ──────────────────────────────────────────────────────────────
GITEA_HOST="${1:-}"
REPO_PATH="${2:-tekketsu/dotfiles}"

if [[ -z "$GITEA_HOST" ]]; then
  # Try loading from machine.conf
  [[ -f "$MACHINE_CONF" ]] && . "$MACHINE_CONF"
  GITEA_HOST="${GITEA_REMOTE_URL:-}"
  [[ -z "$GITEA_HOST" ]] && err "Usage: $0 <gitea-url> [repo-path]
  Examples:
    $0 git@192.168.1.10:tekketsu/dotfiles.git
    $0 https://gitea.lan tekketsu/dotfiles"
fi

# Build SSH URL if host-only given
if [[ "$GITEA_HOST" == http* ]]; then
  GITEA_URL="${GITEA_HOST%/}/${REPO_PATH}.git"
else
  # Already a full SSH URL (git@host:path) or just host
  if [[ "$GITEA_HOST" == *:* ]]; then
    GITEA_URL="$GITEA_HOST"
  else
    GITEA_URL="git@${GITEA_HOST}:${REPO_PATH}.git"
  fi
fi

log "Gitea URL: $GITEA_URL"

# ─── add or update remote ────────────────────────────────────────────────────
if git -C "$REPO_ROOT" remote | grep -q "^gitea$"; then
  log "Updating existing 'gitea' remote"
  git -C "$REPO_ROOT" remote set-url gitea "$GITEA_URL"
else
  log "Adding 'gitea' remote"
  git -C "$REPO_ROOT" remote add gitea "$GITEA_URL"
fi

# ─── verify connectivity (non-fatal) ─────────────────────────────────────────
log "Testing connection to Gitea..."
if git -C "$REPO_ROOT" ls-remote gitea HEAD &>/dev/null; then
  log "Gitea connection: OK"
else
  warn "Could not reach Gitea at $GITEA_URL"
  warn "Make sure:"
  warn "  - Gitea is running on your Proxmox server"
  warn "  - SSH key is added to your Gitea account"
  warn "  - The repo 'tekketsu/dotfiles' exists in Gitea"
  warn "  - Firewall allows port 22 (SSH) or 3000 (HTTP)"
fi

# ─── save to machine.conf ────────────────────────────────────────────────────
if [[ -f "$MACHINE_CONF" ]]; then
  # Update existing entry
  if grep -q "GITEA_REMOTE_URL" "$MACHINE_CONF"; then
    sed -i "s|GITEA_REMOTE_URL=.*|GITEA_REMOTE_URL=$GITEA_URL|" "$MACHINE_CONF"
  else
    echo "GITEA_REMOTE_URL=$GITEA_URL" >> "$MACHINE_CONF"
  fi
else
  echo "GITEA_REMOTE_URL=$GITEA_URL" >> "$MACHINE_CONF"
fi

log "Saved Gitea URL to .machine.conf"
log ""
log "You can now use:"
log "  dev gitea-push              # push main + tag to Gitea"
log "  dev gitea-release           # create a stable release tag"
log "  dev gitea-pull              # pull latest for this machine's profile"
