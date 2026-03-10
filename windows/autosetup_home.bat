@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIGURATION – Download URLs
:: ============================================================
set "STATS_SERVER_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/StatsServer.zip"
set "LIBRIST_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/librist.zip"
:: ============================================================

:: ------------------------------------------------------------
:: AUTO-DOWNLOAD AND EXTRACTION SECTION
:: ------------------------------------------------------------
echo Checking for required files...

:: Download StatsServer.zip if missing
if not exist "StatsServer.zip" (
    echo Downloading StatsServer.zip...
    powershell -Command "Invoke-WebRequest -Uri '%STATS_SERVER_URL%' -OutFile 'StatsServer.zip'"
)

:: Download librist.zip if missing
if not exist "librist.zip" (
    echo Downloading librist.zip...
    powershell -Command "Invoke-WebRequest -Uri '%LIBRIST_URL%' -OutFile 'librist.zip'"
)

:: Extract StatsServer.zip if StatsServer.exe is missing
if not exist "StatsServer.exe" (
    if exist "StatsServer.zip" (
        echo Extracting StatsServer.zip...
        tar -xf "StatsServer.zip"
    )
)

:: Extract librist.zip if librist\tools\ristreceiver.exe is missing
if not exist "librist\tools\ristreceiver.exe" (
    if exist "librist.zip" (
        echo Extracting librist.zip...
        tar -xf "librist.zip"
    )
)

:: Create placeholder files if they don't exist
if not exist "banner.txt" echo placeholder > banner.txt
if not exist "stats.json" echo {} > stats.json

echo File check complete.
echo.

:: ------------------------------------------------------------
:: CREDENTIALS HANDLING (with PORTS - HOME SETUP)
:: ------------------------------------------------------------
:: Set default port values
set "HTTP_PORT=8080"
set "WS_PORT=8081"
set "RIST_RECEIVER_PORT=2030"
set "RIST_SENDER_PORT=5556"
set "LOOPBACK_PORT=12345"
set "STATS_PORT=5005"

:: Check if credentials file exists and load credentials
if exist credentials.txt (
    echo Loading existing credentials from credentials.txt
    set "HAS_HTTP_PORT=0"
    set "HAS_WS_PORT=0"
    set "HAS_RECEIVER_PORT=0"
    set "HAS_SENDER_PORT=0"
    set "HAS_LOOPBACK_PORT=0"
    set "HAS_STATS_PORT=0"
    
    for /f "tokens=1,2 delims==" %%a in (credentials.txt) do (
        if "%%a"=="USERNAME" set "USERNAME=%%b"
        if "%%a"=="PASSWORD" set "PASSWORD=%%b"
        if "%%a"=="HTTP_PORT" (
            set "HTTP_PORT=%%b"
            set "HAS_HTTP_PORT=1"
        )
        if "%%a"=="WS_PORT" (
            set "WS_PORT=%%b"
            set "HAS_WS_PORT=1"
        )
        if "%%a"=="RIST_RECEIVER_PORT" (
            set "RIST_RECEIVER_PORT=%%b"
            set "HAS_RECEIVER_PORT=1"
        )
        if "%%a"=="RIST_SENDER_PORT" (
            set "RIST_SENDER_PORT=%%b"
            set "HAS_SENDER_PORT=1"
        )
        if "%%a"=="LOOPBACK_PORT" (
            set "LOOPBACK_PORT=%%b"
            set "HAS_LOOPBACK_PORT=1"
        )
        if "%%a"=="STATS_PORT" (
            set "STATS_PORT=%%b"
            set "HAS_STATS_PORT=1"
        )
    )
    
    :: Add port defaults if missing
    if !HAS_HTTP_PORT!==0 (
        echo HTTP_PORT=!HTTP_PORT!>> credentials.txt
        echo Added HTTP_PORT=!HTTP_PORT! to credentials.txt
    )
    if !HAS_WS_PORT!==0 (
        echo WS_PORT=!WS_PORT!>> credentials.txt
        echo Added WS_PORT=!WS_PORT! to credentials.txt
    )
    if !HAS_RECEIVER_PORT!==0 (
        echo RIST_RECEIVER_PORT=!RIST_RECEIVER_PORT!>> credentials.txt
        echo Added RIST_RECEIVER_PORT=!RIST_RECEIVER_PORT! to credentials.txt
    )
    if !HAS_SENDER_PORT!==0 (
        echo RIST_SENDER_PORT=!RIST_SENDER_PORT!>> credentials.txt
        echo Added RIST_SENDER_PORT=!RIST_SENDER_PORT! to credentials.txt
    )
    if !HAS_LOOPBACK_PORT!==0 (
        echo LOOPBACK_PORT=!LOOPBACK_PORT!>> credentials.txt
        echo Added LOOPBACK_PORT=!LOOPBACK_PORT! to credentials.txt
    )
    if !HAS_STATS_PORT!==0 (
        echo STATS_PORT=!STATS_PORT!>> credentials.txt
        echo Added STATS_PORT=!STATS_PORT! to credentials.txt
    )
) else (
    :: Generate new random username with "moo-" prefix (max 20 chars total)
    set "chars=abcdefghijklmnopqrstuvwxyz0123456789"
    set "USERNAME=moo-"
    for /L %%i in (1,1,16) do (
        set /a "rand=!random! %% 36"
        for %%c in (!rand!) do set "USERNAME=!USERNAME!!chars:~%%c,1!"
    )

    :: Generate random password (30 characters)
    set "PASSWORD="
    for /L %%i in (1,1,30) do (
        set /a "rand=!random! %% 36"
        for %%c in (!rand!) do set "PASSWORD=!PASSWORD!!chars:~%%c,1!"
    )

    :: Default port values
    set "HTTP_PORT=8080"
    set "WS_PORT=8081"
    set "RIST_RECEIVER_PORT=2030"
    set "RIST_SENDER_PORT=5556"
    set "LOOPBACK_PORT=12345"
    set "STATS_PORT=5005"

    :: Save credentials to file (no trailing spaces!)
    echo USERNAME=!USERNAME!> credentials.txt
    echo PASSWORD=!PASSWORD!>> credentials.txt
    echo HTTP_PORT=!HTTP_PORT!>> credentials.txt
    echo WS_PORT=!WS_PORT!>> credentials.txt
    echo RIST_RECEIVER_PORT=!RIST_RECEIVER_PORT!>> credentials.txt
    echo RIST_SENDER_PORT=!RIST_SENDER_PORT!>> credentials.txt
    echo LOOPBACK_PORT=!LOOPBACK_PORT!>> credentials.txt
    echo STATS_PORT=!STATS_PORT!>> credentials.txt
    echo Credentials saved to credentials.txt
)

:: Always display the credentials and ports being used
echo.
echo Using configuration:
echo USERNAME: !USERNAME!
echo PASSWORD: !PASSWORD!
echo.
echo Port Configuration:
echo HTTP Stats Port: !HTTP_PORT!
echo WebSocket Stats Port: !WS_PORT!
echo RIST Receiver Port: !RIST_RECEIVER_PORT!
echo RIST Sender Port: !RIST_SENDER_PORT!
echo Loopback Port: !LOOPBACK_PORT!
echo Stats Feedback Port: !STATS_PORT!
echo.

:: Verify that required executables exist
if not exist "StatsServer.exe" (
    echo ERROR: StatsServer.exe not found!
    pause
    exit /b 1
)

if not exist "librist\tools\ristreceiver.exe" (
    echo ERROR: ristreceiver.exe not found in librist\tools\
    pause
    exit /b 1
)

if not exist "librist\tools\ristsender.exe" (
    echo ERROR: ristsender.exe not found in librist\tools\
    pause
    exit /b 1
)

echo Starting StatsServer and RIST tools (HOME setup - no encryption)...
echo Press any key to stop all processes and close this window
echo.

:: Set environment variables for StatsServer
set env_udp_port=%STATS_PORT%
set env_http_port=%HTTP_PORT%
set env_ws_port=%WS_PORT%

:: Start StatsServer with configured ports
echo Starting StatsServer.exe on HTTP port !HTTP_PORT! and WS port !WS_PORT!...
start /B "" "StatsServer.exe" -http "0.0.0.0:!HTTP_PORT!" -ws "0.0.0.0:!WS_PORT!"

:: Wait 3 seconds for StatsServer to startup
echo Waiting 3 seconds for StatsServer to initialize...
timeout /t 3 /nobreak >nul

:: Run both RIST commands in background using start /B (no new windows)
echo Starting RIST tools...
start /B "" "librist\tools\ristreceiver.exe" -i "rist://@0.0.0.0:!RIST_RECEIVER_PORT!?rtt-min=100&username=!USERNAME!&password=!PASSWORD!" -o "rist://127.0.0.1:!LOOPBACK_PORT!" -r "127.0.0.1:!STATS_PORT!" -p 1
start /B "" "librist\tools\ristsender.exe" -i "udp://@127.0.0.1:!LOOPBACK_PORT!" -o "rist://@0.0.0.0:!RIST_SENDER_PORT!?cname=moo-rist-relay" -p 1

echo All processes are running in the background:
echo - StatsServer.exe (HTTP:!HTTP_PORT!, WS:!WS_PORT!)
echo - librist\tools\ristreceiver.exe (in:!RIST_RECEIVER_PORT!, loop:!LOOPBACK_PORT!, stats:!STATS_PORT!)
echo - librist\tools\ristsender.exe (out:!RIST_SENDER_PORT!)
echo.
echo HOME Network Configuration:
echo - Receiver: username/password authentication on port !RIST_RECEIVER_PORT! (no encryption)
echo - Forwarder: no encryption on port !RIST_SENDER_PORT! (for local OBS compatibility)
echo - Stats: HTTP !HTTP_PORT!, WebSocket !WS_PORT!
echo.
echo Press any key to stop all processes and close...
pause >nul

:: Kill all processes when key is pressed
echo Stopping all processes...
taskkill /f /im StatsServer.exe >nul 2>&1
taskkill /f /im ristreceiver.exe >nul 2>&1
taskkill /f /im ristsender.exe >nul 2>&1

echo All processes stopped. Closing...
timeout /t 2 /nobreak >nul
