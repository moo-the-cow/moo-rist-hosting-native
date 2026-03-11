#!/bin/bash

# ============================================================
# CONFIGURATION – Download URLs
# ============================================================
STATS_SERVER_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/linux/StatsServer.tar.gz"
LIBRIST_URL="https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/linux/librist.tar.gz"
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
# CREDENTIALS HANDLING (with PORTS - HOME SETUP)
# ------------------------------------------------------------
# Set default port values
HTTP_PORT="8080"
WS_PORT="8081"
RIST_RECEIVER_PORT="2030"
RIST_SENDER_PORT="5556"
LOOPBACK_PORT="12345"
STATS_PORT="5005"

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
            HTTP_PORT) HTTP_PORT="$value" ;;
            WS_PORT) WS_PORT="$value" ;;
            RIST_RECEIVER_PORT) RIST_RECEIVER_PORT="$value" ;;
            RIST_SENDER_PORT) RIST_SENDER_PORT="$value" ;;
            LOOPBACK_PORT) LOOPBACK_PORT="$value" ;;
            STATS_PORT) STATS_PORT="$value" ;;
        esac
    done < "credentials.txt"
    
    # Add port defaults if missing (check if they exist in file)
    if ! grep -q "^HTTP_PORT=" credentials.txt; then
        echo "HTTP_PORT=$HTTP_PORT" >> credentials.txt
        echo "Added HTTP_PORT=$HTTP_PORT to credentials.txt"
    fi
    if ! grep -q "^WS_PORT=" credentials.txt; then
        echo "WS_PORT=$WS_PORT" >> credentials.txt
        echo "Added WS_PORT=$WS_PORT to credentials.txt"
    fi
    if ! grep -q "^RIST_RECEIVER_PORT=" credentials.txt; then
        echo "RIST_RECEIVER_PORT=$RIST_RECEIVER_PORT" >> credentials.txt
        echo "Added RIST_RECEIVER_PORT=$RIST_RECEIVER_PORT to credentials.txt"
    fi
    if ! grep -q "^RIST_SENDER_PORT=" credentials.txt; then
        echo "RIST_SENDER_PORT=$RIST_SENDER_PORT" >> credentials.txt
        echo "Added RIST_SENDER_PORT=$RIST_SENDER_PORT to credentials.txt"
    fi
    if ! grep -q "^LOOPBACK_PORT=" credentials.txt; then
        echo "LOOPBACK_PORT=$LOOPBACK_PORT" >> credentials.txt
        echo "Added LOOPBACK_PORT=$LOOPBACK_PORT to credentials.txt"
    fi
    if ! grep -q "^STATS_PORT=" credentials.txt; then
        echo "STATS_PORT=$STATS_PORT" >> credentials.txt
        echo "Added STATS_PORT=$STATS_PORT to credentials.txt"
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

    # Save credentials to file (no trailing spaces!)
    echo "USERNAME=$USERNAME" > credentials.txt
    echo "PASSWORD=$PASSWORD" >> credentials.txt
    echo "HTTP_PORT=$HTTP_PORT" >> credentials.txt
    echo "WS_PORT=$WS_PORT" >> credentials.txt
    echo "RIST_RECEIVER_PORT=$RIST_RECEIVER_PORT" >> credentials.txt
    echo "RIST_SENDER_PORT=$RIST_SENDER_PORT" >> credentials.txt
    echo "LOOPBACK_PORT=$LOOPBACK_PORT" >> credentials.txt
    echo "STATS_PORT=$STATS_PORT" >> credentials.txt
    echo "Credentials saved to credentials.txt"
fi

# Always display the credentials and ports being used
echo ""
echo "Using configuration:"
echo "USERNAME: $USERNAME"
echo "PASSWORD: $PASSWORD"
echo ""
echo "Port Configuration:"
echo "HTTP Stats Port: $HTTP_PORT"
echo "WebSocket Stats Port: $WS_PORT"
echo "RIST Receiver Port: $RIST_RECEIVER_PORT"
echo "RIST Sender Port: $RIST_SENDER_PORT"
echo "Loopback Port: $LOOPBACK_PORT"
echo "Stats Feedback Port: $STATS_PORT"
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

# Set environment variables for StatsServer
export env_udp_port=$STATS_PORT
export env_http_port=$HTTP_PORT
export env_ws_port=$WS_PORT

# Start StatsServer with configured ports
echo "Starting StatsServer on HTTP port $HTTP_PORT and WS port $WS_PORT..."
./StatsServer -http "0.0.0.0:$HTTP_PORT" -ws "0.0.0.0:$WS_PORT" &
STATS_PID=$!

# Wait 3 seconds for StatsServer to startup
echo "Waiting 3 seconds for StatsServer to initialize..."
sleep 3

# Run both RIST commands in background (no encryption)
echo "Starting RIST tools..."
./librist/tools/ristreceiver -v -1 -i "rist://@0.0.0.0:$RIST_RECEIVER_PORT?rtt-min=100&username=$USERNAME&password=$PASSWORD" -o "rist://127.0.0.1:$LOOPBACK_PORT" -r "127.0.0.1:$STATS_PORT" -p 1 &
RECEIVER_PID=$!

./librist/tools/ristsender -v -1 -i "udp://@127.0.0.1:$LOOPBACK_PORT" -o "rist://@0.0.0.0:$RIST_SENDER_PORT?cname=moo-rist-relay" -p 1 &
SENDER_PID=$!

echo "All processes are running in the background:"
echo "- StatsServer (PID: $STATS_PID, HTTP:$HTTP_PORT, WS:$WS_PORT)"
echo "- ristreceiver (PID: $RECEIVER_PID, in:$RIST_RECEIVER_PORT, loop:$LOOPBACK_PORT, stats:$STATS_PORT)"
echo "- ristsender (PID: $SENDER_PID, out:$RIST_SENDER_PORT)"
echo ""
echo "HOME Network Configuration:"
echo "- Receiver: username/password authentication on port $RIST_RECEIVER_PORT (no encryption)"
echo "- Forwarder: no encryption on port $RIST_SENDER_PORT (for local OBS compatibility)"
echo "- Stats: HTTP $HTTP_PORT, WebSocket $WS_PORT"
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
