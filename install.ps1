# Stop on errors
$ErrorActionPreference = "Stop"

# Source directory (script location)
$SRC = $PSScriptRoot

# Destination directory
$DEST = "C:\ProgramData\Scripts"

Write-Host "Creating destination directory if it doesn't exist..."

if (-not (Test-Path $DEST)) {
    New-Item -ItemType Directory -Path $DEST | Out-Null
}

Write-Host "`nCopying .bat, .ps1 and .vbs files..."

Get-ChildItem -Path $SRC -Filter *.bat | ForEach-Object {
    Copy-Item $_.FullName -Destination $DEST -Force
}

Get-ChildItem -Path $SRC -Filter *.vbs | ForEach-Object {
    Copy-Item $_.FullName -Destination $DEST -Force
}


Get-ChildItem -Path $SRC -Filter *.ps1 | ForEach-Object {
    Copy-Item $_.FullName -Destination $DEST -Force
}

Write-Host "`nImporting scheduled tasks from XML files..."

Get-ChildItem -Path $SRC -Filter *.xml | ForEach-Object {

    $taskName = $_.BaseName
    $xmlPath  = $_.FullName

    Write-Host "Importing task from $($_.Name)..."

    schtasks.exe /Create /TN $taskName /XML $xmlPath /F | Out-Null
}

Write-Host "`nInstallation complete."
Read-Host "Press Enter to continue"
