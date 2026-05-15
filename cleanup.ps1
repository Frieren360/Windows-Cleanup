# Parallel Windows Cleanup Script
# Optimized version with multi-threaded execution for independent operations

param(
    [switch]$SkipRestore = $false,
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = 'SilentlyContinue'

# Configuration
$LogFile = "C:\ProgramData\Scripts\cleanup.log"
$MaxJobs = [System.Environment]::ProcessorCount

# Ensure log directory exists
$LogDir = Split-Path -Parent $LogFile
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

function Start-ParallelJob {
    param(
        [string]$JobName,
        [scriptblock]$ScriptBlock,
        [int]$MaxConcurrentJobs = $MaxJobs
    )
    
    # Wait if we have too many jobs
    while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) {
        Start-Sleep -Milliseconds 100
    }
    
    $job = Start-Job -Name $JobName -ScriptBlock $ScriptBlock
    Write-Log "Started job: $JobName (Job ID: $($job.Id))" "DEBUG"
    return $job
}

function Wait-AllJobs {
    $jobs = Get-Job -State Running
    if ($jobs.Count -gt 0) {
        Write-Log "Waiting for $($jobs.Count) job(s) to complete..."
        $null = Wait-Job -Job $jobs
    }
}

function Report-JobResults {
    param([Array]$Jobs)
    
    $succeeded = 0
    $failed = 0
    
    foreach ($job in $Jobs) {
        $result = Receive-Job -Job $job
        if ($job.State -eq 'Completed') {
            if ($job.HasMoreData) {
                Write-Log "[$($job.Name)] $result"
            }
            $succeeded++
        } else {
            Write-Log "[$($job.Name)] FAILED - Check details above" "ERROR"
            $failed++
        }
        Remove-Job -Job $job
    }
    
    Write-Log "Job Summary: $succeeded succeeded, $failed failed"
    return @{ Succeeded = $succeeded; Failed = $failed }
}

Write-Log "========================================" "INFO"
Write-Log "Windows Cleanup - Parallel Execution" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Maximum concurrent jobs: $MaxJobs"
Write-Log "Verbose mode: $Verbose"

# ============================================================================
# PHASE 1: PRE-CLEANUP - Create System Restore Point (Sequential)
# ============================================================================

if (-not $SkipRestore) {
    Write-Log "PHASE 1: Creating System Restore Point..."
    try {
        Checkpoint-Computer -Description "Cleanup: Pre-cleanup restore point" -RestorePointType MODIFY_SETTINGS
        Write-Log "System Restore point created successfully"
    } catch {
        Write-Log "Warning: Could not create restore point: $_" "WARN"
    }
}

# ============================================================================
# PHASE 2: FILE CLEANUP - Parallel Execution
# ============================================================================

Write-Log "PHASE 2: Starting parallel file cleanup operations..."
$fileJobs = @()

# Job 1: Clear File Explorer Recent Files
$fileJobs += Start-ParallelJob -JobName "Clear-ExplorerRecent" -ScriptBlock {
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue
    "Cleared File Explorer history"
}

# Job 2: Clear Windows Temp Files
$fileJobs += Start-ParallelJob -JobName "Clear-WindowsTemp" -ScriptBlock {
    $tempDirs = @("$env:TEMP", "C:\Windows\Temp")
    foreach ($dir in $tempDirs) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    "Cleared Windows Temp folders"
}

# Job 3: Clear Prefetch
$fileJobs += Start-ParallelJob -JobName "Clear-Prefetch" -ScriptBlock {
    $prefetchPath = "C:\Windows\Prefetch"
    if (Test-Path $prefetchPath) {
        Get-ChildItem -Path $prefetchPath -Force | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    "Cleared Prefetch"
}

# Job 4: Clear Microsoft Edge Data
$fileJobs += Start-ParallelJob -JobName "Clear-EdgeData" -ScriptBlock {
    # Kill Edge if running
    Stop-Process -Name "msedge", "msedgewebview2" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    $edgePaths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\Crashpad",
        "$env:LOCALAPPDATA\Microsoft\Edge\Temp"
    )
    
    foreach ($path in $edgePaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    "Cleared Edge browser data"
}

# Job 5: Clear Icon Cache and Thumbnails
$fileJobs += Start-ParallelJob -JobName "Clear-IconCache" -ScriptBlock {
    $cachePaths = @(
        "$env:LOCALAPPDATA\IconCache.db",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"
    )
    
    foreach ($path in $cachePaths) {
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
    "Cleared icon and thumbnail cache"
}

# Job 6: Clear Recycle Bin
$fileJobs += Start-ParallelJob -JobName "Clear-RecycleBin" -ScriptBlock {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    "Emptied Recycle Bin"
}

# Job 7: Clear Desktop Files
$fileJobs += Start-ParallelJob -JobName "Clear-Desktop" -ScriptBlock {
    $desktopPath = "$env:USERPROFILE\Desktop"
    if (Test-Path $desktopPath) {
        Get-ChildItem -Path $desktopPath -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
    "Cleared Desktop files"
}

# Job 8: Clear Notepad History
$fileJobs += Start-ParallelJob -JobName "Clear-NotepadHistory" -ScriptBlock {
    $notepadPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState"
    if (Test-Path $notepadPath) {
        Remove-Item -Path $notepadPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    "Cleared Notepad history"
}

Wait-AllJobs
$fileResults = Report-JobResults -Jobs $fileJobs

# ============================================================================
# PHASE 3: REGISTRY CLEANUP - Parallel Execution
# ============================================================================

Write-Log "PHASE 3: Starting parallel registry cleanup operations..."
$regJobs = @()

# Job 1: Clear Run History
$regJobs += Start-ParallelJob -JobName "Clear-RunHistory" -ScriptBlock {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    if (Test-Path $regPath) {
        Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
    }
    "Cleared Run history"
}

# Job 2: Clear Taskbar Settings
$regJobs += Start-ParallelJob -JobName "Clear-TaskbarSettings" -ScriptBlock {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $regPath -Name "TaskbarAl" -Value 1 -ErrorAction SilentlyContinue
    "Set taskbar alignment to center"
}

# Job 3: Clear Remote Desktop History
$regJobs += Start-ParallelJob -JobName "Clear-RDPHistory" -ScriptBlock {
    $rdpPaths = @(
        "HKCU:\Software\Microsoft\Terminal Server Client\Default",
        "HKCU:\Software\Microsoft\Terminal Server Client\Servers",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2"
    )
    
    foreach ($path in $rdpPaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
    "Cleared Remote Desktop history"
}

# Job 4: Clear Start Menu Layout
$regJobs += Start-ParallelJob -JobName "Clear-StartMenu" -ScriptBlock {
    $layoutPaths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml",
        "$env:LOCALAPPDATA\Microsoft\Windows\Shell\DefaultLayouts.xml"
    )
    
    foreach ($path in $layoutPaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        }
    }
    "Cleared Start Menu layout"
}

Wait-AllJobs
$regResults = Report-JobResults -Jobs $regJobs

# ============================================================================
# PHASE 4: NETWORK OPERATIONS - Parallel Execution
# ============================================================================

Write-Log "PHASE 4: Starting parallel network cleanup operations..."
$networkJobs = @()

# Job 1: Flush DNS Cache
$networkJobs += Start-ParallelJob -JobName "Flush-DNSCache" -ScriptBlock {
    ipconfig /flushdns | Out-Null
    "Flushed DNS cache"
}

# Job 2: Remove Mapped Network Drives
$networkJobs += Start-ParallelJob -JobName "Remove-MappedDrives" -ScriptBlock {
    net use * /delete /y 2>$null
    "Removed mapped network drives"
}

# Job 3: Clear SMB Mappings
$networkJobs += Start-ParallelJob -JobName "Clear-SMBMappings" -ScriptBlock {
    Get-SmbMapping -ErrorAction SilentlyContinue | Remove-SmbMapping -Force -UpdateProfile -ErrorAction SilentlyContinue
    "Cleared SMB mappings"
}

# Job 4: Clear Saved Credentials
$networkJobs += Start-ParallelJob -JobName "Clear-SavedCredentials" -ScriptBlock {
    $credentials = cmdkey /list 2>$null | Select-String "Target:"
    foreach ($cred in $credentials) {
        $target = $cred.Line -replace ".*Target: ", ""
        cmdkey /delete:$target 2>$null
    }
    "Cleared saved credentials"
}

# Job 5: Clear Network Cache
$networkJobs += Start-ParallelJob -JobName "Clear-NetworkCache" -ScriptBlock {
    net stop workstation /y 2>$null
    Start-Sleep -Seconds 2
    net start workstation 2>$null
    "Cleared network cache"
}

Wait-AllJobs
$networkResults = Report-JobResults -Jobs $networkJobs

# ============================================================================
# PHASE 5: SYSTEM OPTIMIZATION - Sequential
# ============================================================================

Write-Log "PHASE 5: System optimization and finalization..."

# Clear Clipboard
try {
    echo off | clip
    Write-Log "Cleared clipboard"
} catch {
    Write-Log "Warning: Could not clear clipboard: $_" "WARN"
}

# Reset Explorer pinned apps
try {
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $taskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    if (Test-Path $taskbarPath) {
        Remove-Item -Path "$taskbarPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    Write-Log "Reset Taskbar pinned apps"
} catch {
    Write-Log "Warning: Could not reset taskbar: $_" "WARN"
}

# Set desktop wallpaper
try {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 1920, 1080
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.Clear([System.Drawing.Color]::FromArgb(30, 144, 255))  # Dodger Blue
    $wallpaperPath = "$env:TEMP\bluewall.bmp"
    $bmp.Save($wallpaperPath)
    
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $wallpaperPath -ErrorAction SilentlyContinue
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    
    Write-Log "Set blue desktop wallpaper"
} catch {
    Write-Log "Warning: Could not set wallpaper: $_" "WARN"
}

# Restart Explorer
try {
    Start-Process -FilePath explorer.exe
    Write-Log "Restarted Windows Explorer"
} catch {
    Write-Log "Warning: Could not restart Explorer: $_" "WARN"
}

# ============================================================================
# PHASE 6: SYSTEM RESTORE - Create Fresh Restore Point
# ============================================================================

if (-not $SkipRestore) {
    Write-Log "PHASE 6: Creating post-cleanup System Restore point..."
    try {
        Checkpoint-Computer -Description "Cleanup: Post-cleanup restore point" -RestorePointType MODIFY_SETTINGS
        Write-Log "Post-cleanup System Restore point created successfully"
    } catch {
        Write-Log "Warning: Could not create post-cleanup restore point: $_" "WARN"
    }
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-Log "========================================" "INFO"
Write-Log "Cleanup Completed Successfully" "INFO"
Write-Log "========================================" "INFO"
Write-Log "File Operations: $($fileResults.Succeeded) succeeded, $($fileResults.Failed) failed"
Write-Log "Registry Operations: $($regResults.Succeeded) succeeded, $($regResults.Failed) failed"
Write-Log "Network Operations: $($networkResults.Succeeded) succeeded, $($networkResults.Failed) failed"
Write-Log "Log saved to: $LogFile"
Write-Log "========================================" "INFO"
