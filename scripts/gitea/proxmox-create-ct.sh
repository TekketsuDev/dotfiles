#!/usr/bin/env bash
# proxmox-create-ct.sh — create the Gitea LXC container on Proxmox
# Run this ON the Proxmox host (via SSH or the host shell)
#
# Usage:
#   bash proxmox-create-ct.sh
#   CTID=201 CT_IP=192.168.1.55 bash proxmox-create-ct.sh
set -euo pipefail

# ─── config — edit these or pass as env vars ─────────────────────────────────
CTID="${CTID:-200}"
HOSTNAME="${CT_HOSTNAME:-gitea}"
STORAGE="${CT_STORAGE:-local-lvm}"        # where the rootfs lives
TEMPLATE_STORE="${CT_TMPL_STORE:-local}"  # where templates are downloaded to
MEMORY="${CT_MEMORY:-512}"                # MB
CORES="${CT_CORES:-1}"
DISK="${CT_DISK:-8}"                      # GB
BRIDGE="${CT_BRIDGE:-vmbr0}"
CT_IP="${CT_IP:-192.168.1.50}"
CT_GW="${CT_GW:-192.168.1.1}"
CT_NETMASK="${CT_NETMASK:-24}"
ROOT_PW="${CT_ROOT_PW:-}"                 # leave blank to be prompted

# Debian 12 — change if you want a different distro
TEMPLATE_NAME="debian-12-standard_12.2-1_amd64.tar.zst"

_g='\033[0;32m'; _y='\033[0;33m'; _r='\033[0;31m'; _b='\033[1;34m'; _n='\033[0m'
log()  { printf "${_g}[pve]${_n} %s\n" "$*"; }
warn() { printf "${_y}[warn]${_n} %s\n" "$*"; }
err()  { printf "${_r}[err]${_n} %s\n" "$*" >&2; exit 1; }
step() { printf "\n${_b}==> %s${_n}\n" "$*"; }

# ─── checks ──────────────────────────────────────────────────────────────────
command -v pct &>/dev/null || err "pct not found — run this on the Proxmox host"

if pct status "$CTID" &>/dev/null; then
  err "CT $CTID already exists. Use a different CTID."
fi

if [[ -z "$ROOT_PW" ]]; then
  read -rsp "Root password for CT $CTID: " ROOT_PW; echo
  [[ -z "$ROOT_PW" ]] && err "Password cannot be empty"
fi

# ─── download template if missing ────────────────────────────────────────────
step "Checking template"
TMPL_PATH="/var/lib/vz/template/cache/$TEMPLATE_NAME"
if [[ ! -f "$TMPL_PATH" ]]; then
  log "Downloading $TEMPLATE_NAME..."
  # Find the latest available name
  AVAILABLE=$(pveam available --section system | grep "debian-12" | awk '{print $2}' | head -1)
  if [[ -n "$AVAILABLE" ]]; then
    TEMPLATE_NAME="$AVAILABLE"
    log "Using: $TEMPLATE_NAME"
    pveam download "$TEMPLATE_STORE" "$TEMPLATE_NAME"
  else
    warn "Could not auto-find Debian 12 template. Trying with: $TEMPLATE_NAME"
    pveam download "$TEMPLATE_STORE" "$TEMPLATE_NAME" || err "Template download failed"
  fi
else
  log "Template already present: $TEMPLATE_NAME"
fi

# ─── create CT ───────────────────────────────────────────────────────────────
step "Creating CT $CTID ($HOSTNAME)"
pct create "$CTID" "${TEMPLATE_STORE}:vztmpl/${TEMPLATE_NAME}" \
  --hostname    "$HOSTNAME" \
  --memory      "$MEMORY" \
  --cores       "$CORES" \
  --rootfs      "${STORAGE}:${DISK}" \
  --net0        "name=eth0,bridge=${BRIDGE},ip=${CT_IP}/${CT_NETMASK},gw=${CT_GW}" \
  --nameserver  "$CT_GW" \
  --unprivileged 1 \
  --features    "nesting=1,keyctl=1" \
  --password    "$ROOT_PW" \
  --start       0

# Enable user namespaces (required for Nix in unprivileged CT)
step "Enabling user namespaces for Nix compatibility"
echo "lxc.sysctl.user.max_user_namespaces = 15000" >> "/etc/pve/lxc/${CTID}.conf"

# ─── start ───────────────────────────────────────────────────────────────────
step "Starting CT $CTID"
pct start "$CTID"
sleep 3

log "CT $CTID is running"
log ""
log "Next: copy and run gitea-install.sh inside the container"
log ""
log "  # copy script into CT"
log "  pct push $CTID ./scripts/gitea/gitea-install.sh /root/gitea-install.sh"
log ""
log "  # run it"
log "  pct exec $CTID -- bash /root/gitea-install.sh"
log ""
log "  # or SSH in directly after install"
log "  ssh root@$CT_IP -p 2222"
log ""
log "Gitea will be at: http://${CT_IP}:3000"
log "Git SSH will be:  git@${CT_IP}:user/repo.git"
