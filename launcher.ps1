# Parallel Cleanup Launcher
# Enhanced version of launcher.ps1 that runs the parallel cleanup script

param(
    [switch]$SkipRestore = $false,
    [switch]$Verbose = $false,
    [switch]$DryRun = $false
)

# Ensure script runs from its own directory
$ScriptDir = $PSScriptRoot

# Load config (dot-sourcing so variables persist)
$ConfigPath = Join-Path $ScriptDir "config.ps1"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: Missing config.ps1"
    exit 1
}

. $ConfigPath

# Derived variables
$CLEANUP_SCRIPT = Join-Path $SCRIPT_DIR "parallel-cleanup.ps1"
$DEST_DIR_CLEANUP = "$DEST_DIR\parallel-cleanup.ps1"
$LOG_FILE_PARALLEL = "$DEST_DIR\parallel-cleanup.log"

Write-Host "========================================"
Write-Host "Parallel Windows Cleanup Launcher"
Write-Host "========================================"
Write-Host "Script Directory: $SCRIPT_DIR"
Write-Host "Config Path: $ConfigPath"
Write-Host "Installation Directory: $DEST_DIR"

# Ensure script directory exists
if (-not (Test-Path $DEST_DIR)) {
    New-Item -ItemType Directory -Path $DEST_DIR | Out-Null
    Write-Host "Created directory: $DEST_DIR"
}

Write-Host ""
Write-Host "Checking for parallel cleanup script..."

# Copy parallel cleanup script if needed
if (Test-Path $CLEANUP_SCRIPT) {
    if (-not (Test-Path $DEST_DIR_CLEANUP)) {
        Write-Host "Copying parallel cleanup script..."
        Copy-Item $CLEANUP_SCRIPT $DEST_DIR_CLEANUP -Force
    } else {
        Write-Host "Parallel cleanup script already installed."
    }
} else {
    Write-Host "ERROR: parallel-cleanup.ps1 not found in $SCRIPT_DIR"
    exit 1
}

Write-Host ""
Write-Host "Launching parallel cleanup..."
Write-Host ""

# Build arguments
$arguments = @()
if ($SkipRestore) { $arguments += "-SkipRestore" }
if ($Verbose) { $arguments += "-Verbose" }
if ($DryRun) { $arguments += "-DryRun" }

# Run the parallel cleanup script
if (Test-Path $DEST_DIR_CLEANUP) {
    & powershell -ExecutionPolicy Bypass -File $DEST_DIR_CLEANUP @arguments 2>&1 | Tee-Object -FilePath $LOG_FILE_PARALLEL -Append
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Cleanup complete. Check the log:"
    Write-Host $LOG_FILE_PARALLEL
    Write-Host "========================================"
} else {
    Write-Host "Failed to locate cleanup script at: $DEST_DIR_CLEANUP"
    exit 1
}
