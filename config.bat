@echo off

:: === CONFIG VARIABLES ===

:: Host Machine IP address
set "HOST_MACHINE="

:: Network source for script clean-fixed.bat
set "SOURCE=%~dp0clean-fixed.bat"

:: Local install directory
set "DEST_DIR=C:\ProgramData\Scripts"

:: Log file location
set "LOG_FILE=C:\ProgramData\Scripts\run.log"
