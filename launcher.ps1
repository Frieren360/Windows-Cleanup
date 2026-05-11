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
$DEST = Join-Path $DEST_DIR "clean-fixed.bat"

Write-Host "Ensuring script directory exists..."

if (-not (Test-Path $DEST_DIR)) {
    New-Item -ItemType Directory -Path $DEST_DIR | Out-Null
}

Write-Host "Checking for updates..."

# If destination doesn't exist, copy immediately
if (-not (Test-Path $DEST)) {
    Write-Host "No local copy found. Downloading..."
    Copy-Item $SOURCE $DEST -Force
}
else {
    # Compare timestamps
    $srcTime = (Get-Item $SOURCE).LastWriteTime
    $dstTime = (Get-Item $DEST).LastWriteTime

    if ($srcTime -eq $dstTime) {
        Write-Host "Script is up to date. Skipping download."
    }
    else {
        Write-Host "New version detected. Updating..."
        Copy-Item $SOURCE $DEST -Force
    }
}

# Run script
if (Test-Path $DEST) {
    Write-Host "Running main script..."

    & cmd.exe /c "`"$DEST`"" 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
}
else {
    Write-Host "Failed to retrieve script."
}
