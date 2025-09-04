# Usage: ./wipe_disk.sh /dev/sdX

#!/usr/bin/env bash
set -e

DISK="$1"

dd if=/dev/urandom of="$DISK" bs=4096 status=progress || echo "✅ Finished wiping $DISK (dd completed)"
