#!/usr/bin/env bash
set -e

echo "🔐 Hardening SSH configuration..."

SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original config
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%F_%T)"

# Apply hardened settings
cat <<EOF >> "$SSHD_CONFIG"

# 💡 Hardened SSH Settings
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
AllowUsers $USER
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

systemctl restart sshd || systemctl restart ssh

