#!/bin/sh

# 1. Substitute variables inside rclone config file
sed -i "s|PLACEHOLDER_KEY_ID|$R2_ACCESS_KEY_ID|g" /root/.config/rclone/rclone.conf
sed -i "s|PLACEHOLDER_SECRET_KEY|$R2_SECRET_ACCESS_KEY|g" /root/.config/rclone/rclone.conf
sed -i "s|PLACEHOLDER_ENDPOINT|$R2_ENDPOINT_URL|g" /root/.config/rclone/rclone.conf

# 2. Pull down existing books from the cloud storage to /tmp/books upon cold boot
echo "Initial sync: Downloading libraries from Cloudflare R2..."
rclone sync r2:books /tmp/books --verbose

# 3. Continuous background watcher: scans every 15 seconds to back up newly added books
echo "Starting continuous background cloud sync loop..."
while true; do
  # Sync local writes up to the cloud bucket silently
  rclone sync /tmp/books r2:bookorbit-library --quiet
  sleep 15
done
