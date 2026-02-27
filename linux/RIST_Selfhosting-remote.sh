#!/bin/bash

# Check if credentials file exists and load credentials
if [ -f "credentials.txt" ]; then
    echo "Loading existing credentials from credentials.txt"
    source credentials.txt
    
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

    # Save credentials to file
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

echo "Starting StatsServer and RIST tools (REMOTE version with encryption)..."
echo "Press Ctrl+C to stop all processes and close this window"
echo ""

# Start StatsServer first
echo "Starting StatsServer..."
chmod +x ./StatsServer
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
chmod +x ./librist/tools/ristreceiver
./librist/tools/ristreceiver -i "$RECEIVER_URL" -o "rist://127.0.0.1:12345" -r "127.0.0.1:5005" -p 1 &
RECEIVER_PID=$!

chmod +x ./librist/tools/ristsender
./librist/tools/ristsender -i "udp://@127.0.0.1:12345" -o "rist://@0.0.0.0:5556?cname=moo-rist-relay&aes-type=$ENCRYPTION&secret=$SECRET" -p 1 &
SENDER_PID=$!

echo "All processes are running in the background:"
echo "- StatsServer (PID: $STATS_PID)"
echo "- ristreceiver (PID: $RECEIVER_PID)"
echo "- ristsender (PID: $SENDER_PID)"
echo ""
echo "REMOTE Configuration:"
if [ "$NOAUTH" = "true" ]; then
    echo "- Receiver: no authentication, encryption enabled"
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
