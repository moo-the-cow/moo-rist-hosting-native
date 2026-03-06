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
# CREDENTIALS HANDLING (with NOAUTH and ENCRYPTION)
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
            SECRET) SECRET="$value" ;;
            NOAUTH) NOAUTH="$value" ;;
            ENCRYPTION) ENCRYPTION="$value" ;;
        esac
    done < "credentials.txt"
    
    # Set defaults for new variables if not present
    if [ -z "$NOAUTH" ]; then
        NOAUTH="false"
        # Append default NOAUTH to file if not already there
        if ! grep -q "^NOAUTH=" credentials.txt; then
            echo "NOAUTH=false" >> credentials.txt
            echo "Added NOAUTH=false to credentials.txt"
        fi
    fi
    
    if [ -z "$ENCRYPTION" ]; then
        ENCRYPTION="128"
        if ! grep -q "^ENCRYPTION=" credentials.txt; then
            echo "ENCRYPTION=128" >> credentials.txt
            echo "Added ENCRYPTION=128 to credentials.txt"
        fi
    fi
    
    # Check if SECRET exists in credentials, if not generate and add it
    if [ -z "$SECRET" ]; then
        echo "SECRET not found in credentials.txt, generating new secret..."
        chars="abcdefghijklmnopqrstuvwxyz0123456789"
        SECRET=""
        for i in {1..42}; do
            rand=$((RANDOM % 36))
            SECRET="${SECRET}${chars:$rand:1}"
        done
        echo "SECRET=$SECRET" >> credentials.txt
        echo "Added SECRET to credentials.txt"
    fi
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

    # Generate random secret (42 characters for encryption)
    SECRET=""
    for i in {1..42}; do
        rand=$((RANDOM % 36))
        SECRET="${SECRET}${chars:$rand:1}"
    done

    # Default values for new settings
    NOAUTH="false"
    ENCRYPTION="128"

    # Save credentials to file (no trailing spaces!)
    echo "USERNAME=$USERNAME" > credentials.txt
    echo "PASSWORD=$PASSWORD" >> credentials.txt
    echo "SECRET=$SECRET" >> credentials.txt
    echo "NOAUTH=$NOAUTH" >> credentials.txt
    echo "ENCRYPTION=$ENCRYPTION" >> credentials.txt
    echo "Credentials saved to credentials.txt"
fi

# Always display the credentials being used
echo ""
echo "Using credentials:"
echo "USERNAME: $USERNAME"
echo "PASSWORD: $PASSWORD"
echo "SECRET: $SECRET"
echo "NOAUTH: $NOAUTH"
echo "ENCRYPTION: $ENCRYPTION"
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

echo "Starting StatsServer and RIST tools (REMOTE version with encryption)..."
echo "Press Ctrl+C to stop all processes and close this window"
echo ""

# Start StatsServer first
echo "Starting StatsServer..."
./StatsServer &
STATS_PID=$!

# Wait 3 seconds for StatsServer to startup
echo "Waiting 3 seconds for StatsServer to initialize..."
sleep 3

# Build receiver URL based on NOAUTH setting
if [ "$NOAUTH" = "true" ]; then
    RECEIVER_URL="rist://@0.0.0.0:2030?rtt-min=100&aes-type=$ENCRYPTION&secret=$SECRET"
else
    RECEIVER_URL="rist://@0.0.0.0:2030?rtt-min=100&username=$USERNAME&password=$PASSWORD"
fi

# Run both RIST commands in background with encryption
echo "Starting RIST tools with encryption..."
./librist/tools/ristreceiver -i "$RECEIVER_URL" -o "rist://127.0.0.1:12345" -r "127.0.0.1:5005" -p 1 &
RECEIVER_PID=$!

./librist/tools/ristsender -i "udp://@127.0.0.1:12345" -o "rist://@0.0.0.0:5556?cname=moo-rist-relay&aes-type=$ENCRYPTION&secret=$SECRET" -p 1 &
SENDER_PID=$!

echo "All processes are running in the background:"
echo "- StatsServer (PID: $STATS_PID)"
echo "- ristreceiver (PID: $RECEIVER_PID)"
echo "- ristsender (PID: $SENDER_PID)"
echo ""
echo "REMOTE Configuration:"
if [ "$NOAUTH" = "true" ]; then
    echo "- Receiver: no authentication, $ENCRYPTION-bit encryption"
else
    echo "- Receiver: username/password + encryption"
fi
echo "- Forwarder: encryption only (for OBS compatibility)"
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
