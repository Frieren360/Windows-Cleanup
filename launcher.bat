
@echo off
setlocal

if not exist "%~dp0config.bat" (
    echo ERROR: Missing config.bat
    exit /b 1
)

:: Load config
call "%~dp0config.bat"

:: Derived variables
set "DEST=%DEST_DIR%\clean-fixed.bat"

echo Ensuring script directory exists...
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Checking for updates...

:: If destination doesn't exist, copy immediately
if not exist "%DEST%" (
    echo No local copy found. Downloading...
    copy "%SOURCE%" "%DEST%" >nul
    goto run
)

:: Compare timestamps
for %%A in ("%SOURCE%") do set SRC_DATE=%%~tA
for %%A in ("%DEST%") do set DST_DATE=%%~tA

if "%SRC_DATE%"=="%DST_DATE%" (
    echo Script is up to date. Skipping download.
) else (
    echo New version detected. Updating...
    copy "%SOURCE%" "%DEST%" /Y >nul
)

:run
if exist "%DEST%" (
    echo Running main script...
    call "%DEST%" >> "%LOG_FILE%" 2>&1
) else (
    echo Failed to retrieve script.
)