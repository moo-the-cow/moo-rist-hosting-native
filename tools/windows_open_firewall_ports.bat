@echo off
:: ============================================================
:: RIST Relay Firewall Configuration - Windows
:: Opens ports 2030/UDP and 5556/UDP
:: REQUIRES ADMINISTRATOR PRIVILEGES
:: ============================================================

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo RIST Relay Firewall Configuration
echo ================================
echo.
echo This script will open the following ports in Windows Firewall:
echo - Port 2030 UDP (RIST receiver)
echo - Port 5556 UDP (RIST sender)
echo.
echo Checking existing firewall rules...

:: Check if port 2030 UDP rule already exists
netsh advfirewall firewall show rule name="RIST Relay 2030 UDP" >nul 2>&1
if %errorLevel% equ 0 (
    echo Port 2030 UDP rule already exists. Skipping...
) else (
    echo Adding firewall rule for port 2030 UDP...
    netsh advfirewall firewall add rule name="RIST Relay 2030 UDP" protocol=udp localport=2030 action=allow dir=in
    if %errorLevel% equ 0 (
        echo Successfully added rule for port 2030 UDP
    ) else (
        echo Failed to add rule for port 2030 UDP
    )
)

:: Check if port 5556 UDP rule already exists
netsh advfirewall firewall show rule name="RIST Relay 5556 UDP" >nul 2>&1
if %errorLevel% equ 0 (
    echo Port 5556 UDP rule already exists. Skipping...
) else (
    echo Adding firewall rule for port 5556 UDP...
    netsh advfirewall firewall add rule name="RIST Relay 5556 UDP" protocol=udp localport=5556 action=allow dir=in
    if %errorLevel% equ 0 (
        echo Successfully added rule for port 5556 UDP
    ) else (
        echo Failed to add rule for port 5556 UDP
    )
)

echo.
echo Firewall configuration complete!
echo.
echo Current rules for RIST Relay:
netsh advfirewall firewall show rule name="RIST Relay 2030 UDP" | find "LocalPort"
netsh advfirewall firewall show rule name="RIST Relay 5556 UDP" | find "LocalPort"
echo.
echo Press any key to exit...
pause >nul
