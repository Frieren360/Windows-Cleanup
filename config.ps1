# === CONFIG VARIABLES ===

# Host Machine IP address
$HOST_MACHINE = ""

# Directory where this script lives (equivalent to %~dp0)
$SCRIPT_DIR = $PSScriptRoot

# Network source for script clean-fixed.bat
$SOURCE = Join-Path $SCRIPT_DIR "clean-fixed.bat"

# Network source for script install.ps1
$INSTALL_SOURCE = Join-Path $SCRIPT_DIR "install.ps1"

# Local install directory
$DEST_DIR = "C:\ProgramData\Scripts"

# Log file location
$LOG_FILE = "C:\ProgramData\Scripts\run.log"

$EnablePreRestorePoint = $true

$SkipRestorePoint = $false
