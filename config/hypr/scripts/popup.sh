#!/usr/bin/env bash

APP=""
POSITION="top-right"
ARGS=()

# Argument parser
while [[ $# -gt 0 ]]; do
    case "$1" in
        --top-left|--top-right|--bottom-left|--bottom-right|--center)
            POSITION="${1#--}"  # Strip the -- prefix
            shift
            ;;
        *)
            if [[ -z "$APP" ]]; then
                APP="$1"
            else
                ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

TITLE="popup-$(date +%s)"
MARGIN=20

# Monitor info
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
MON_X=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .x")
MON_Y=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .y")
MON_W=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .width")
MON_H=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .height")

# Window size
WIN_W=$(( MON_W * 40 / 100 ))
WIN_H=$(( MON_H * 35 / 100 ))

# Positioning logic
case "$POSITION" in
    top-left)
        POS_X=$(( MON_X + MARGIN ))
        POS_Y=$(( MON_Y + MARGIN ))
        ;;
    top-right)
        POS_X=$(( MON_X + MON_W - WIN_W - MARGIN ))
        POS_Y=$(( MON_Y + MARGIN ))
        ;;
    bottom-left)
        POS_X=$(( MON_X + MARGIN ))
        POS_Y=$(( MON_Y + MON_H - WIN_H - MARGIN ))
        ;;
    bottom-right)
        POS_X=$(( MON_X + MON_W - WIN_W - MARGIN ))
        POS_Y=$(( MON_Y + MON_H - WIN_H - MARGIN ))
        ;;
    center)
        POS_X=$(( MON_X + (MON_W - WIN_W) / 2 ))
        POS_Y=$(( MON_Y + (MON_H - WIN_H) / 2 ))
        ;;
    *)
        echo "⚠️ Invalid position flag: $POSITION"
        exit 1
        ;;
esac

# Launch app with dynamic title
hyprctl dispatch exec "[workspace; float; size ${WIN_W} ${WIN_H}; title ${TITLE}] ${APP} --title ${TITLE} ${ARGS[*]}" &
sleep 0.5

# Wait for window
for i in {1..15}; do
    ADDR=$(hyprctl clients -j | jq -r ".[] | select(.title==\"$TITLE\") | .address")
    [[ -n "$ADDR" ]] && break
    sleep 0.2
done

if [[ -z "$ADDR" ]]; then
    echo "❌ Could not find window"
    exit 1
fi

# Move the window to final position
hyprctl dispatch movewindowpixel exact ${POS_X} ${POS_Y},address:$ADDR

echo "✅ Launched popup '$APP' at $POSITION"
echo "$TITLE" > ~/.cache/hypr-special-title

