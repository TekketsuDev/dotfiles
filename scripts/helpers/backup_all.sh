#!/bin/bash

SOURCE_DIRS="/home /etc /boot"
TARGET_USER="backup"
TARGET_HOST="192.168.0.18"
DEST_PATH="/home/backups/zen_28-11-2024_partial"

echo "Starting sync..."
sudo rsync -avz --progress --exclude=/home/lost+found $SOURCE_DIRS $TARGET_USER@$TARGET_HOST:$DEST_PATH

echo "Sync complet. Verify the files on the target machine."
