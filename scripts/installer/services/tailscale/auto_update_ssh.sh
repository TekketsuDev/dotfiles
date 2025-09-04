#!/usr/bin/env bash
set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"
KEY_PATH="$HOME/.ssh/id_ed25519_tailscale"
DEFAULT_USER="root"
DEFAULT_PORT=22

# Asegura que jq esté instalado
command -v jq >/dev/null || { echo "❌ Requiere jq instalado"; exit 1; }

# Asegura que tailscale esté activo
command -v tailscale >/dev/null || { echo "❌ Requiere tailscale instalado"; exit 1; }

echo "🔍 Detectando dispositivos Tailscale accesibles..."

# Obtiene todos los peers que están online
TS_PEERS=$(tailscale status --json | jq -c '.Peer[] | select(.Online == true)')

mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG"

add_or_update_host() {
    local HOST_ALIAS="$1"
    local HOST_IP="$2"

    if grep -q "Host $HOST_ALIAS" "$SSH_CONFIG"; then
        echo "🔁 Actualizando $HOST_ALIAS..."
        # Usamos una técnica de reemplazo por bloque
        sed -i "/Host $HOST_ALIAS/,/^\s*$/c\
Host $HOST_ALIAS\n\
    HostName $HOST_IP\n\
    User $DEFAULT_USER\n\
    IdentityFile $KEY_PATH\n\
    Port $DEFAULT_PORT\n\
    IdentitiesOnly yes\n\
    ServerAliveInterval 60\n\
    ServerAliveCountMax 3\n" "$SSH_CONFIG"
    else
        echo "➕ Añadiendo $HOST_ALIAS..."
        cat >> "$SSH_CONFIG" <<EOF

Host $HOST_ALIAS
    HostName $HOST_IP
    User $DEFAULT_USER
    IdentityFile $KEY_PATH
    Port $DEFAULT_PORT
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    fi
}

# Iterar sobre cada peer
echo "$TS_PEERS" | while IFS= read -r peer; do
    HOSTNAME=$(echo "$peer" | jq -r '.HostName')
    IP=$(echo "$peer" | jq -r '.TailscaleIPs[0]')

    # Nombre del host para SSH (alias)
    HOST_ALIAS="ts-$HOSTNAME"

    # Añadir o actualizar
    add_or_update_host "$HOST_ALIAS" "$IP"
done

echo "✅ SSH config actualizado con dispositivos Tailscale disponibles."

