#!/usr/bin/env bash
# gitea-install.sh — install Gitea binary + systemd inside the LXC CT
# Run INSIDE the container:
#   pct exec <CTID> -- bash /root/gitea-install.sh
#   OR: bash gitea-install.sh after SSHing in
#
# After install:
#   Web UI  → http://<CT_IP>:3000  (first visit = setup wizard)
#   Git SSH → git@<CT_IP>:user/repo.git
#   Admin SSH (system) → ssh root@<CT_IP> -p 2222
set -euo pipefail

# ─── config ──────────────────────────────────────────────────────────────────
GITEA_VERSION="${GITEA_VERSION:-1.22.3}"
GITEA_USER="git"
GITEA_HOME="/var/lib/gitea"
GITEA_CONF="/etc/gitea"
GITEA_BIN="/usr/local/bin/gitea"
HTTP_PORT="${GITEA_HTTP_PORT:-3000}"
SSH_PORT=22            # Gitea git SSH
ADMIN_SSH_PORT=2222    # system sshd (moved here to free port 22 for Gitea)
DOMAIN="${GITEA_DOMAIN:-}"   # auto-detected from IP if blank

_g='\033[0;32m'; _y='\033[0;33m'; _r='\033[0;31m'; _b='\033[1;34m'; _n='\033[0m'
log()  { printf "${_g}[gitea]${_n} %s\n" "$*"; }
warn() { printf "${_y}[warn]${_n} %s\n" "$*"; }
err()  { printf "${_r}[err]${_n} %s\n" "$*" >&2; exit 1; }
step() { printf "\n${_b}==> %s${_n}\n" "$*"; }

[[ "$EUID" -ne 0 ]] && err "Run as root"

# ─── detect IP ───────────────────────────────────────────────────────────────
if [[ -z "$DOMAIN" ]]; then
  DOMAIN=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/{print $7; exit}' || hostname -I | awk '{print $1}')
fi
log "Gitea domain/IP: $DOMAIN"

# ─── system update + deps ────────────────────────────────────────────────────
step "System update"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q curl git openssh-server

# ─── move system sshd to port 2222 (frees port 22 for Gitea git SSH) ────────
step "Moving sshd to port $ADMIN_SSH_PORT"
sed -i "s/^#\?Port .*/Port $ADMIN_SSH_PORT/" /etc/ssh/sshd_config
grep -q "^Port $ADMIN_SSH_PORT" /etc/ssh/sshd_config || echo "Port $ADMIN_SSH_PORT" >> /etc/ssh/sshd_config
systemctl restart sshd || service ssh restart
log "sshd now on port $ADMIN_SSH_PORT"

# ─── create git user ─────────────────────────────────────────────────────────
step "Creating '$GITEA_USER' system user"
if ! id "$GITEA_USER" &>/dev/null; then
  adduser --system --shell /bin/bash --gecos "Gitea" \
    --group --disabled-password --home "$GITEA_HOME" "$GITEA_USER"
fi

# ─── directories ─────────────────────────────────────────────────────────────
step "Setting up directories"
mkdir -p "$GITEA_HOME"/{custom,data,log,repositories,.ssh}
mkdir -p "$GITEA_CONF"
chown -R "$GITEA_USER:$GITEA_USER" "$GITEA_HOME" "$GITEA_CONF"
chmod 750 "$GITEA_HOME" "$GITEA_CONF"
chmod 700 "$GITEA_HOME/.ssh"

# ─── download Gitea binary ───────────────────────────────────────────────────
step "Downloading Gitea $GITEA_VERSION"
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
  amd64)  GITEA_ARCH="amd64" ;;
  arm64)  GITEA_ARCH="arm64" ;;
  armhf)  GITEA_ARCH="arm-6" ;;
  *)      GITEA_ARCH="amd64"; warn "Unknown arch $ARCH, using amd64" ;;
esac

GITEA_URL="https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-${GITEA_ARCH}"
curl -fSL "$GITEA_URL" -o "$GITEA_BIN"
chmod +x "$GITEA_BIN"
log "Gitea binary: $($GITEA_BIN --version | head -1)"

# ─── app.ini ─────────────────────────────────────────────────────────────────
step "Writing app.ini"
cat > "$GITEA_CONF/app.ini" <<INI
APP_NAME = tekketsu Gitea
RUN_USER = $GITEA_USER
RUN_MODE = prod

[server]
DOMAIN           = $DOMAIN
HTTP_PORT        = $HTTP_PORT
ROOT_URL         = http://$DOMAIN:$HTTP_PORT/
SSH_DOMAIN       = $DOMAIN
SSH_PORT         = $SSH_PORT
SSH_LISTEN_PORT  = $SSH_PORT
DISABLE_SSH      = false
START_SSH_SERVER = false   ; use system SSH + AuthorizedKeysCommand (more robust)
BUILTIN_SSH_SERVER_USER = $GITEA_USER

[database]
DB_TYPE  = sqlite3
PATH     = $GITEA_HOME/data/gitea.db

[repository]
ROOT = $GITEA_HOME/repositories

[security]
INSTALL_LOCK       = false   ; false = first-visit setup wizard runs
SECRET_KEY         =         ; auto-generated on first start
INTERNAL_TOKEN     =

[log]
ROOT_PATH = $GITEA_HOME/log
MODE      = file
LEVEL     = info

[service]
DISABLE_REGISTRATION              = false
REQUIRE_SIGNIN_VIEW               = false
DEFAULT_KEEP_EMAIL_PRIVATE        = true
DEFAULT_ALLOW_CREATE_ORGANIZATION = true

[ssh.minimum_key_sizes]
ED25519 = 256
ECDSA   = 256
RSA     = 2048
INI

chown "$GITEA_USER:$GITEA_USER" "$GITEA_CONF/app.ini"
chmod 640 "$GITEA_CONF/app.ini"

# ─── SSH AuthorizedKeysCommand (routes git@ SSH to Gitea) ────────────────────
step "Configuring SSH AuthorizedKeysCommand"
# Allows: ssh git@<IP> → Gitea handles key lookup in its DB
cat >> /etc/ssh/sshd_config <<SSHCFG

# Gitea git SSH routing
Match User $GITEA_USER
    AuthorizedKeysCommandUser $GITEA_USER
    AuthorizedKeysCommand $GITEA_BIN keys -e git -u %u -t %t -k %k
    AuthorizedKeysFile .ssh/authorized_keys
SSHCFG

# Re-add port 22 for git@ connections (sshd listens on both 22 and 2222)
grep -q "^Port 22$" /etc/ssh/sshd_config || echo "Port 22" >> /etc/ssh/sshd_config
systemctl restart sshd || service ssh restart
log "SSH configured: port 22 (git) + port $ADMIN_SSH_PORT (admin)"

# ─── systemd service ─────────────────────────────────────────────────────────
step "Creating systemd service"
cat > /etc/systemd/system/gitea.service <<UNIT
[Unit]
Description=Gitea — self-hosted git service
After=network.target

[Service]
Type=simple
User=$GITEA_USER
Group=$GITEA_USER
WorkingDirectory=$GITEA_HOME
ExecStart=$GITEA_BIN web --config $GITEA_CONF/app.ini
Restart=always
RestartSec=5
Environment=USER=$GITEA_USER HOME=$GITEA_HOME GITEA_WORK_DIR=$GITEA_HOME
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now gitea
sleep 2

if systemctl is-active --quiet gitea; then
  log "Gitea service: running"
else
  warn "Gitea service may have failed to start. Check: journalctl -u gitea -n 30"
fi

# ─── summary ─────────────────────────────────────────────────────────────────
step "Done"
echo ""
echo "  Web UI     → http://$DOMAIN:$HTTP_PORT"
echo "  Git SSH    → git@$DOMAIN:username/repo.git"
echo "  Admin SSH  → ssh root@$DOMAIN -p $ADMIN_SSH_PORT"
echo ""
echo "  First visit to the web UI runs the setup wizard."
echo "  Create an admin account, then add your SSH key."
echo ""
echo "  From your dotfiles:"
echo "    dev gitea-add git@$DOMAIN:tekketsu/dotfiles.git"
echo ""
