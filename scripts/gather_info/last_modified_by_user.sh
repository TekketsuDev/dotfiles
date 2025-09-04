#!/bin/bash

# Create a folder to store user logs
LOG_DIR="$HOME/user_file_logs"
mkdir -p "$LOG_DIR"

# Get all system users from /etc/passwd
echo "Extracting user list..."
USERS=$(awk -F':' '{ if ($3 >= 1000 && $3 < 60000) print $1 }' /etc/passwd)

# Loop through each user and find their last modified files
for USER in $USERS; do
    LOG_FILE="$LOG_DIR/${USER}_files.txt"
    echo "Processing user: $USER -> $LOG_FILE"

    # Find last modified files owned by the user (depth = 10)
    find / -maxdepth 10 -type f -user "$USER" -printf "%T@ %Tc | %p \n" 2>/dev/null \
    | sort -n -r > "$LOG_FILE"

    # Check if the file contains data
    if [ ! -s "$LOG_FILE" ]; then
        echo "No recent files found for user $USER." > "$LOG_FILE"
    fi
done

echo "✅ All user files have been saved in $LOG_DIR"

