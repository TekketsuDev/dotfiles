#!/usr/bin/env bash
echo "follow_showmethekey.sh started" >> /tmp/showmethekey.log

# Evita duplicados del script
SCRIPT_NAME=$(basename "$0")
PIDFILE="/tmp/${SCRIPT_NAME}.pid"
if [[ -f "$PIDFILE" ]]; then
    OLD_PID=$(cat "$PIDFILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Script ya está corriendo con PID $OLD_PID" >> /tmp/showmethekey.log
        exit 0
    fi
fi
echo $$ > "$PIDFILE"

# Limpieza al salir
cleanup() {
    echo "🧼 Limpieza..." >> /tmp/showmethekey.log
    pkill -f 'showmethekey-gtk -A -C'
    [[ -f "$PIDFILE" ]] && rm "$PIDFILE"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

LAST_WS_ID=""

while sleep 0.5; do
    CLIENT=$(hyprctl clients -j | jq -c '.[] | select(.class == "showmethekey-gtk")')
    [[ -z "$CLIENT" ]] && continue

    WS_ID=$(hyprctl activeworkspace -j | jq -r '.id')

    if [[ "$WS_ID" != "$LAST_WS_ID" ]]; then
        echo "🧹 Workspace changed: $LAST_WS_ID → $WS_ID" >> /tmp/showmethekey.log
        pkill -f 'showmethekey-gtk -A -C'
        sleep 0.2
        showmethekey-gtk -A -C
        LAST_WS_ID="$WS_ID"
    fi
done
