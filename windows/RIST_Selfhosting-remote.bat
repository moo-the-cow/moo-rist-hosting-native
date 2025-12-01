@echo off
setlocal enabledelayedexpansion

:: Check if credentials file exists and load credentials
if exist credentials.txt (
    echo Loading existing credentials from credentials.txt
    set "HAS_SECRET=0"
    for /f "tokens=1,2 delims==" %%a in (credentials.txt) do (
        if "%%a"=="USERNAME" set "USERNAME=%%b"
        if "%%a"=="PASSWORD" set "PASSWORD=%%b"
        if "%%a"=="SECRET" (
            set "SECRET=%%b"
            set "HAS_SECRET=1"
        )
    )
    
    :: Check if SECRET exists in credentials, if not generate and add it
    if !HAS_SECRET!==0 (
        echo SECRET not found in credentials.txt, generating new secret...
        set "chars=abcdefghijklmnopqrstuvwxyz0123456789"
        set "SECRET="
        for /L %%i in (1,1,42) do (
            set /a "rand=!random! %% 36"
            for %%c in (!rand!) do set "SECRET=!SECRET!!chars:~%%c,1!"
        )
        echo. >> credentials.txt
        echo SECRET=!SECRET! >> credentials.txt
        echo Added SECRET to credentials.txt
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

    :: Generate random secret (42 characters for encryption)
    set "SECRET="
    for /L %%i in (1,1,42) do (
        set /a "rand=!random! %% 36"
        for %%c in (!rand!) do set "SECRET=!SECRET!!chars:~%%c,1!"
    )

    :: Save credentials to file
    echo USERNAME=!USERNAME! > credentials.txt
    echo PASSWORD=!PASSWORD! >> credentials.txt
    echo SECRET=!SECRET! >> credentials.txt
    echo Credentials saved to credentials.txt
)

:: Always display the credentials being used
echo.
echo Using credentials:
echo USERNAME: !USERNAME!
echo PASSWORD: !PASSWORD!
echo SECRET: !SECRET!
echo ENCRYPTION: 128
echo.

echo Starting StatsServer and RIST tools ^(REMOTE version with encryption^)...
echo Press any key to stop all processes and close this window
echo.

:: Start StatsServer first
echo Starting StatsServer.exe...
start /B "" StatsServer.exe

:: Wait 3 seconds for StatsServer to startup
echo Waiting 3 seconds for StatsServer to initialize...
timeout /t 3 /nobreak >nul

:: Run both RIST commands in background using start /B (no new windows) with encryption
echo Starting RIST tools with encryption...
start /B "" librist\tools\ristreceiver.exe -i "rist://@0.0.0.0:2030?rtt-min=100&username=!USERNAME!&password=!PASSWORD!" -o "rist://127.0.0.1:12345" -r "127.0.0.1:5005" -p 1
start /B "" librist\tools\ristsender.exe -i "udp://@127.0.0.1:12345" -o "rist://@0.0.0.0:5556?cname=moo-rist-relay&aes-type=128&secret=!SECRET!" -p 1

echo All processes are running in the background:
echo - StatsServer.exe
echo - librist\tools\ristreceiver.exe
echo - librist\tools\ristsender.exe
echo.
echo REMOTE Configuration:
echo - Receiver: username/password + encryption
echo - Forwarder: encryption only ^(for OBS compatibility^)
echo.
echo Press any key to stop all processes and close...
pause >nul

:: Kill all processes when key is pressed
taskkill /f /im StatsServer.exe >nul 2>&1
taskkill /f /im ristreceiver.exe >nul 2>&1
taskkill /f /im ristsender.exe >nul 2>&1

echo All processes stopped. Closing...
