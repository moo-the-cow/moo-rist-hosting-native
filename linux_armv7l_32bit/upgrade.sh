#!/bin/bash

# ============================================================
# CONFIGURATION – Download URLs
# ============================================================
STATS_SERVER_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/linux_armv7l_32bit/StatsServer.tar.gz"
LIBRIST_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/linux_armv7l_32bit/librist.tar.gz"
# ============================================================

echo "Upgrading..."

# Stop running processes
pkill -f StatsServer 2>/dev/null
pkill -f ristreceiver 2>/dev/null
pkill -f ristsender 2>/dev/null

# Download and extract StatsServer.tar.gz (force overwrite with current timestamp)
curl -L -o "StatsServer.tar.gz" "$STATS_SERVER_URL"
tar -xzmf "StatsServer.tar.gz"  # -m flag prevents using timestamps from archive
touch StatsServer banner.txt logfile.json 2>/dev/null
chmod +x StatsServer
echo "Replaced: StatsServer"
echo "Replaced: banner.txt"
echo "Replaced: logfile.json"

# Download and extract librist.tar.gz (force overwrite with current timestamp)
curl -L -o "librist.tar.gz" "$LIBRIST_URL"
tar -xzmf "librist.tar.gz"  # -m flag prevents using timestamps from archive
find librist -type f -exec touch {} \; 2>/dev/null  # Reset all file timestamps
chmod +x librist/tools/ristreceiver
chmod +x librist/tools/ristsender
echo "Replaced: librist/tools/ristreceiver"
echo "Replaced: librist/tools/ristsender"

# Cleanup
#rm -f "StatsServer.tar.gz"
#rm -f "librist.tar.gz"

echo ""
echo "Upgrade complete!"
