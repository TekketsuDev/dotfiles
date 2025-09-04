#!/bin/bash
FILENAME="screenshot-$(date +'%Y%m%d-%H%M%S').png"
grim -g "$(slurp)" "$ATTACHMENTS/$FILENAME"
notify-send "📸 Screenshot saved" "$ATTACHMENTS/$FILENAME"

