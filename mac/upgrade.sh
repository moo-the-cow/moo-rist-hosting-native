#!/bin/bash

# ============================================================
# CONFIGURATION – Download URLs
# ============================================================
STATS_SERVER_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/StatsServer.tar.gz"
LIBRIST_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/librist.tar.gz"
HOME_SH_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/autosetup_home.sh"
REMOTE_SH_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/autosetup_remote.sh"
# ============================================================

echo "Upgrading..."

# Stop running processes
pkill -f StatsServer 2>/dev/null
pkill -f ristreceiver 2>/dev/null
pkill -f ristsender 2>/dev/null

# Download and extract StatsServer.tar.gz
curl -L -o "StatsServer.tar.gz" "$STATS_SERVER_URL"
tar -xzf "StatsServer.tar.gz"
chmod +x StatsServer
echo "Replaced: StatsServer"
echo "Replaced: banner.txt"
echo "Replaced: logfile.json"

# Download and extract librist.tar.gz
curl -L -o "librist.tar.gz" "$LIBRIST_URL"
tar -xzf "librist.tar.gz"
chmod +x librist/tools/ristreceiver
chmod +x librist/tools/ristsender
echo "Replaced: librist/tools/ristreceiver"
echo "Replaced: librist/tools/ristsender"

# Download additional shell scripts
curl -L -o "autosetup_home.sh" "$HOME_SH_URL"
chmod +x autosetup_home.sh
echo "Replaced: autosetup_home.sh"

curl -L -o "autosetup_remote.sh" "$REMOTE_SH_URL"
chmod +x autosetup_remote.sh
echo "Replaced: autosetup_remote.sh"

# Cleanup archives (optional, uncomment if desired)
# rm -f "StatsServer.tar.gz"
# rm -f "librist.tar.gz"

echo ""
echo "Upgrade complete!"
