#!/bin/sh

# Ensure rclone config path is correct
RCLONE_CONFIG="/app/rclone.conf"

# Check if config file exists
if [ ! -f "$RCLONE_CONFIG" ]; then
  echo "Error: rclone config file not found at $RCLONE_CONFIG"
  exit 1
fi

# Validate required environment variables
if [ -z "$R2_ACCESS_KEY_ID" ]; then
  echo "Error: R2_ACCESS_KEY_ID environment variable not set"
  exit 1
fi

if [ -z "$R2_SECRET_ACCESS_KEY" ]; then
  echo "Error: R2_SECRET_ACCESS_KEY environment variable not set"
  exit 1
fi

if [ -z "$R2_ENDPOINT_URL" ]; then
  echo "Error: R2_ENDPOINT_URL environment variable not set"
  exit 1
fi

# 1. Substitute variables inside rclone config file
sed -i "s|PLACEHOLDER_KEY_ID|$R2_ACCESS_KEY_ID|g" "$RCLONE_CONFIG"
sed -i "s|PLACEHOLDER_SECRET_KEY|$R2_SECRET_ACCESS_KEY|g" "$RCLONE_CONFIG"
sed -i "s|PLACEHOLDER_ENDPOINT|$R2_ENDPOINT_URL|g" "$RCLONE_CONFIG"

# 2. Pull down existing books from the cloud storage to /tmp/books upon cold boot
echo "Initial sync: Downloading libraries from Cloudflare R2..."
rclone --config="$RCLONE_CONFIG" sync r2:books /tmp/books --verbose

# 3. Continuous background watcher: scans every 15 seconds to back up newly added books
echo "Starting continuous background cloud sync loop..."
(
  while true; do
    # Sync local writes up to the cloud bucket silently
    rclone --config="$RCLONE_CONFIG" sync /tmp/books r2:books --quiet
    sleep 15
  done
) &
