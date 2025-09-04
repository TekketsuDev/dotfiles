#!/usr/bin/env bash

APP="$1"

MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

MON_W=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .width")
MON_H=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .height")

# Calculate dynamic window size
WIN_W=$(( MON_W * 40 / 100 ))
WIN_H=$(( MON_H * 35 / 100 ))

MARGIN=10
POS_X=$(( MON_W - WIN_W - MARGIN ))
POS_Y=$MARGIN

ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')
TITLE="hypr-float-$(date +%s)"

hyprctl dispatch exec "[workspace $ACTIVE_WS;float;size ${WIN_W} ${WIN_H};title ${TITLE}] $APP --title ${TITLE}"

# Step 2: Wait for window to spawn and get address
for i in {1..20}; do
    ADDR=$(hyprctl clients -j | jq -r ".[] | select(.title==\"$TITLE\") | .address")
    if [[ -n "$ADDR" ]]; then
        break
    fi
    sleep 0.2
done

if [[ -z "$ADDR" ]]; then
    echo "❌ Failed to find window titled $TITLE"
    exit 1
fi

hyprctl dispatch pin,address:$ADDR
# Step 3: Force move to position
#hyprctl dispatch movewindowpixel exact $POS_X $POS_Y,address:$ADDR

# Optional: store PID for follow-window service
mkdir -p ~/.cache/hypr-follow
pgrep -f -- "$APP --title ${TITLE}" | head -n1 > ~/.cache/hypr-follow/follow.pid

