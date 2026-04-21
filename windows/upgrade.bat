@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIGURATION – Download URLs
:: ============================================================
set "STATS_SERVER_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/StatsServer.zip"
set "LIBRIST_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/librist.zip"
set "HOME_BAT_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/autosetup_home.bat"
set "REMOTE_BAT_URL=https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/windows/autosetup_remote.bat"
:: ============================================================

echo Upgrading...

:: Stop running processes
taskkill /f /im StatsServer.exe >nul 2>&1
taskkill /f /im ristreceiver.exe >nul 2>&1
taskkill /f /im ristsender.exe >nul 2>&1

:: Download and extract StatsServer.zip
powershell -Command "Invoke-WebRequest -Uri '%STATS_SERVER_URL%' -OutFile 'StatsServer.zip'"
tar -xf "StatsServer.zip"
echo Replaced: StatsServer.exe
echo Replaced: banner.txt
echo Replaced: logfile.json

:: Download and extract librist.zip
powershell -Command "Invoke-WebRequest -Uri '%LIBRIST_URL%' -OutFile 'librist.zip'"
tar -xf "librist.zip"
echo Replaced: librist\tools\ristreceiver.exe
echo Replaced: librist\tools\ristsender.exe

:: Download additional .bat scripts
powershell -Command "Invoke-WebRequest -Uri '%HOME_BAT_URL%' -OutFile 'autosetup_home.bat'"
echo Replaced: autosetup_home.bat

powershell -Command "Invoke-WebRequest -Uri '%REMOTE_BAT_URL%' -OutFile 'autosetup_remote.bat'"
echo Replaced: autosetup_remote.bat

:: Cleanup
:: del "StatsServer.zip" >nul
:: del "librist.zip" >nul

echo Upgrade complete!
pause
