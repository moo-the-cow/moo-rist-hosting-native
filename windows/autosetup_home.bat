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
:: CREDENTIALS HANDLING (HOME SETUP - NO ENCRYPTION)
:: ------------------------------------------------------------
:: Check if credentials file exists and load credentials
if exist credentials.txt (
    echo Loading existing credentials from credentials.txt
    for /f "tokens=1,2 delims==" %%a in (credentials.txt) do (
        if "%%a"=="USERNAME" set "USERNAME=%%b"
        if "%%a"=="PASSWORD" set "PASSWORD=%%b"
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

    :: Save credentials to file (no trailing spaces!)
    echo USERNAME=!USERNAME!> credentials.txt
    echo PASSWORD=!PASSWORD!>> credentials.txt
    echo Credentials saved to credentials.txt
)

:: Remove any trailing carriage return or spaces from credentials (just in case)
for /f "tokens=1,2 delims==" %%a in (credentials.txt) do (
    if "%%a"=="USERNAME" set "USERNAME=%%b"
    if "%%a"=="PASSWORD" set "PASSWORD=%%b"
)

:: Always display the credentials being used
echo.
echo Using credentials:
echo USERNAME: !USERNAME!
echo PASSWORD: !PASSWORD!
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

:: Start StatsServer first
echo Starting StatsServer.exe...
start /B "" "StatsServer.exe"

:: Wait 3 seconds for StatsServer to startup
echo Waiting 3 seconds for StatsServer to initialize...
timeout /t 3 /nobreak >nul

:: Run both RIST commands in background using start /B (no new windows)
echo Starting RIST tools...
start /B "" "librist\tools\ristreceiver.exe" -i "rist://@0.0.0.0:2030?rtt-min=100&username=!USERNAME!&password=!PASSWORD!" -o "rist://127.0.0.1:12345" -r "127.0.0.1:5005" -p 1
start /B "" "librist\tools\ristsender.exe" -i "udp://@127.0.0.1:12345" -o "rist://@0.0.0.0:5556?cname=moo-rist-relay" -p 1

echo All processes are running in the background:
echo - StatsServer.exe
echo - librist\tools\ristreceiver.exe
echo - librist\tools\ristsender.exe
echo.
echo HOME Network Configuration:
echo - Receiver: username/password authentication (no encryption)
echo - Forwarder: no encryption (for local OBS compatibility)
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
