#!/bin/bash

# ============================================================
# RIST Relay Firewall Configuration - Linux
# Opens ports 2030/UDP and 5556/UDP
# REQUIRES SUDO PRIVILEGES
# Supports: iptables, ufw, firewalld
# ============================================================

# Text colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}This script requires root privileges.${NC}"
    echo -e "Please run with: ${YELLOW}sudo $0${NC}"
    exit 1
fi

echo "RIST Relay Firewall Configuration"
echo "================================"
echo ""
echo "This script will open the following ports:"
echo "- Port 2030 UDP (RIST receiver)"
echo "- Port 5556 UDP (RIST sender)"
echo ""

# Detect which firewall is available
FIREWALL=""
if command -v ufw &> /dev/null; then
    FIREWALL="ufw"
elif command -v firewall-cmd &> /dev/null; then
    FIREWALL="firewalld"
elif command -v iptables &> /dev/null; then
    FIREWALL="iptables"
else
    echo -e "${RED}No supported firewall found!${NC}"
    echo "This script supports: ufw, firewalld, iptables"
    exit 1
fi

echo -e "Detected firewall: ${GREEN}$FIREWALL${NC}"
echo ""

# Function to check if port is already open
check_port() {
    local port=$1
    local protocol=$2
    
    case $FIREWALL in
        ufw)
            ufw status | grep -q "$port/$protocol"
            return $?
            ;;
        firewalld)
            firewall-cmd --list-ports | grep -q "$port/$protocol"
            return $?
            ;;
        iptables)
            iptables -L INPUT -n -v | grep -q "dpt:$port"
            return $?
            ;;
    esac
}

# Function to open port
open_port() {
    local port=$1
    local protocol=$2
    local description=$3
    
    echo -n "Checking port $port/$protocol... "
    
    if check_port $port $protocol; then
        echo -e "${YELLOW}already open${NC}"
    else
        echo -n "opening... "
        case $FIREWALL in
            ufw)
                ufw allow $port/$protocol comment "$description" &>/dev/null
                ;;
            firewalld)
                firewall-cmd --permanent --add-port=$port/$protocol &>/dev/null
                firewall-cmd --reload &>/dev/null
                ;;
            iptables)
                iptables -A INPUT -p $protocol --dport $port -j ACCEPT &>/dev/null
                # Save rules if possible
                if command -v iptables-save &>/dev/null; then
                    iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
                    iptables-save > /etc/sysconfig/iptables 2>/dev/null || true
                fi
                ;;
        esac
        
        # Verify it worked
        if check_port $port $protocol; then
            echo -e "${GREEN}success${NC}"
        else
            echo -e "${RED}failed${NC}"
        fi
    fi
}

# Open the required ports
open_port 2030 udp "RIST Receiver"
open_port 5556 udp "RIST Sender"

echo ""
echo -e "${GREEN}Firewall configuration complete!${NC}"
echo ""

# Show current status
echo "Current firewall status:"
echo "-----------------------"
case $FIREWALL in
    ufw)
        ufw status | grep -E "2030|5556"
        ;;
    firewalld)
        firewall-cmd --list-ports | grep -E "2030|5556" || echo "No RIST ports found in permanent config"
        echo ""
        echo "Runtime ports:"
        firewall-cmd --list-ports
        ;;
    iptables)
        iptables -L INPUT -n -v | grep -E "dpt:2030|dpt:5556" || echo "No RIST ports found in iptables rules"
        ;;
esac

echo ""
echo "Note: These ports will persist through reboots:"
case $FIREWALL in
    ufw)
        echo "- ufw rules are persistent by default"
        ;;
    firewalld)
        echo "- firewalld rules have been made permanent"
        ;;
    iptables)
        echo "- iptables rules have been saved if possible"
        echo "  You may need to install iptables-persistent for automatic loading"
        ;;
esac

echo ""
read -p "Press Enter to exit..." 
