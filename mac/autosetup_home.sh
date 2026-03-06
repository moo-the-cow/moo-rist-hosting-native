#!/bin/bash

# ============================================================
# CONFIGURATION – Download URLs
# ============================================================
STATS_SERVER_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/StatsServer.tar.gz"
LIBRIST_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/mac/librist.tar.gz"
# ============================================================

# ------------------------------------------------------------
# AUTO-DOWNLOAD AND EXTRACTION SECTION
# ------------------------------------------------------------
echo "Checking for required files..."

# Download StatsServer.tar.gz if missing
if [ ! -f "StatsServer.tar.gz" ]; then
    echo "Downloading StatsServer.tar.gz..."
    curl -L -o "StatsServer.tar.gz" "$STATS_SERVER_URL"
fi

# Download librist.tar.gz if missing
if [ ! -f "librist.tar.gz" ]; then
    echo "Downloading librist.tar.gz..."
    curl -L -o "librist.tar.gz" "$LIBRIST_URL"
fi

# Extract StatsServer.tar.gz if StatsServer binary is missing
if [ ! -f "StatsServer" ]; then
    if [ -f "StatsServer.tar.gz" ]; then
        echo "Extracting StatsServer.tar.gz..."
        tar -xzf "StatsServer.tar.gz"
        # Make StatsServer executable
        chmod +x StatsServer 2>/dev/null || true
    fi
fi

# Extract librist.tar.gz if librist/tools/ristreceiver is missing
if [ ! -f "librist/tools/ristreceiver" ]; then
    if [ -f "librist.tar.gz" ]; then
        echo "Extracting librist.tar.gz..."
        tar -xzf "librist.tar.gz"
        # Make RIST tools executable
        chmod +x librist/tools/ristreceiver 2>/dev/null || true
        chmod +x librist/tools/ristsender 2>/dev/null || true
    fi
fi

# Create placeholder files if they don't exist
if [ ! -f "banner.txt" ]; then
    echo "placeholder" > banner.txt
fi
if [ ! -f "stats.json" ]; then
    echo "{}" > stats.json
fi

echo "File check complete."
echo ""

# ------------------------------------------------------------
# CREDENTIALS HANDLING (HOME SETUP - NO ENCRYPTION)
# ------------------------------------------------------------
# Check if credentials file exists and load credentials
if [ -f "credentials.txt" ]; then
    echo "Loading existing credentials from credentials.txt"
    
    # Read credentials line by line to avoid trailing spaces
    while IFS='=' read -r key value; do
        # Remove any trailing carriage return or spaces from the value
        value=$(echo "$value" | tr -d '\r' | sed 's/[[:space:]]*$//')
        case "$key" in
            USERNAME) USERNAME="$value" ;;
            PASSWORD) PASSWORD="$value" ;;
        esac
    done < "credentials.txt"
else
    # Generate random username with "moo-" prefix (max 20 chars total)
    chars="abcdefghijklmnopqrstuvwxyz0123456789"
    USERNAME="moo-"
    for i in {1..16}; do
        rand=$((RANDOM % 36))
        USERNAME="${USERNAME}${chars:$rand:1}"
    done

    # Generate random password (30 characters)
    PASSWORD=""
    for i in {1..30}; do
        rand=$((RANDOM % 36))
        PASSWORD="${PASSWORD}${chars:$rand:1}"
    done

    # Save credentials to file (no trailing spaces!)
    echo "USERNAME=$USERNAME" > credentials.txt
    echo "PASSWORD=$PASSWORD" >> credentials.txt
    echo "Credentials saved to credentials.txt"
fi

# Remove any trailing carriage return or spaces from credentials (just in case)
while IFS='=' read -r key value; do
    value=$(echo "$value" | tr -d '\r' | sed 's/[[:space:]]*$//')
    case "$key" in
        USERNAME) USERNAME="$value" ;;
        PASSWORD) PASSWORD="$value" ;;
    esac
done < "credentials.txt"

# Always display the credentials being used
echo ""
echo "Using credentials:"
echo "USERNAME: $USERNAME"
echo "PASSWORD: $PASSWORD"
echo ""

# Verify that required binaries exist
if [ ! -f "./StatsServer" ]; then
    echo "ERROR: StatsServer binary not found!"
    exit 1
fi

if [ ! -f "./librist/tools/ristreceiver" ] || [ ! -f "./librist/tools/ristsender" ]; then
    echo "ERROR: RIST tools not found in librist/tools/"
    exit 1
fi

echo "Starting StatsServer and RIST tools (HOME setup - no encryption)..."
echo "Press Ctrl+C to stop all processes and close this window"
echo ""

# Start StatsServer first
echo "Starting StatsServer..."
./StatsServer &
STATS_PID=$!

# Wait 3 seconds for StatsServer to startup
echo "Waiting 3 seconds for StatsServer to initialize..."
sleep 3

# Build receiver URL (no encryption for home setup)
RECEIVER_URL="rist://@0.0.0.0:2030?rtt-min=100&username=$USERNAME&password=$PASSWORD"

# Run both RIST commands in background (no encryption)
echo "Starting RIST tools..."
./librist/tools/ristreceiver -i "$RECEIVER_URL" -o "rist://127.0.0.1:12345" -r "127.0.0.1:5005" -p 1 &
RECEIVER_PID=$!

./librist/tools/ristsender -i "udp://@127.0.0.1:12345" -o "rist://@0.0.0.0:5556?cname=moo-rist-relay" -p 1 &
SENDER_PID=$!

echo "All processes are running in the background:"
echo "- StatsServer (PID: $STATS_PID)"
echo "- ristreceiver (PID: $RECEIVER_PID)"
echo "- ristsender (PID: $SENDER_PID)"
echo ""
echo "HOME Network Configuration:"
echo "- Receiver: username/password authentication (no encryption)"
echo "- Forwarder: no encryption (for local OBS compatibility)"
echo ""
echo "Press Ctrl+C to stop all processes"

# Function to clean up processes
cleanup() {
    echo ""
    echo "Stopping all processes..."
    kill $STATS_PID 2>/dev/null
    kill $RECEIVER_PID 2>/dev/null
    kill $SENDER_PID 2>/dev/null
    echo "All processes stopped. Exiting..."
    exit 0
}

# Set trap to catch Ctrl+C and cleanup
trap cleanup SIGINT

# Wait indefinitely until Ctrl+C
while true; do
    sleep 1
done
