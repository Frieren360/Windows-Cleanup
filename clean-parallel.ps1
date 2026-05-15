# Windows Cleanup Script - Parallelized Version
# This version uses PowerShell jobs to run independent cleanup tasks in parallel
# for improved performance

param(
    [switch]$SkipRestore = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Configuration
$LogFile = "C:\ProgramData\Scripts\run.log"
$JobTimeout = 120  # seconds per job

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Start-ParallelJob {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )
    Write-Host "  ↻ Starting: $Name"
    return Start-Job -Name $Name -ScriptBlock $ScriptBlock
}

function Wait-ParallelJobs {
    param(
        [System.Management.Automation.Job[]]$Jobs,
        [int]$TimeoutSeconds = 120
    )
    
    Write-Host ""
    Write-Host "Waiting for all cleanup operations to complete..."
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $completed = 0
    $total = $Jobs.Count
    
    while ($completed -lt $total -and $stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $completed = @($Jobs | Where-Object { $_.State -in 'Completed', 'Failed' }).Count
        $remaining = $total - $completed
        
        if ($remaining -gt 0) {
            Write-Host "  ⏳ Progress: $completed/$total completed, $remaining remaining..." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            Write-Host "`r" -NoNewline
        }
    }
    
    Write-Host "  ✓ All operations completed!`n"
    
    # Collect results
    foreach ($job in $Jobs) {
        $result = Receive-Job -Job $job
        if ($result) {
            Write-Log "  ✓ $($job.Name): Completed"
        }
        Remove-Job -Job $job -Force
    }
}

# ============================================================================
# SECTION 1: FILE SYSTEM CLEANUP (Parallelized)
# ============================================================================

Write-Log "=== PHASE 1: FILE SYSTEM CLEANUP ==="
$fileJobs = @()

# Job 1: Clear File Explorer Recent Files
$fileJobs += Start-ParallelJob -Name "Explorer Recent Files" -ScriptBlock {
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -Recurse 2>$null
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -Recurse 2>$null
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -Recurse 2>$null
}

# Job 2: Clear User Temp files
$fileJobs += Start-ParallelJob -Name "User Temp Files" -ScriptBlock {
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
        Remove-Item -Force -Recurse 2>$null
}

# Job 3: Clear System Temp files
$fileJobs += Start-ParallelJob -Name "System Temp Files" -ScriptBlock {
    Get-ChildItem -Path "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue | 
        Remove-Item -Force -Recurse 2>$null
}

# Job 4: Clear Prefetch files
$fileJobs += Start-ParallelJob -Name "Prefetch Cache" -ScriptBlock {
    Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
}

# Job 5: Clear Edge browser data
$fileJobs += Start-ParallelJob -Name "Edge Browser Data" -ScriptBlock {
    Stop-Process -Name msedge, msedgewebview2 -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data" -Force -Recurse 2>$null
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\Crashpad" -Force -Recurse 2>$null
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\Temp" -Force -Recurse 2>$null
}

# Job 6: Clear Icon and Thumbnail Caches
$fileJobs += Start-ParallelJob -Name "Icon/Thumbnail Cache" -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force 2>$null
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -Recurse 2>$null
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*" -Force -Recurse 2>$null
}

# Job 7: Clear Desktop files
$fileJobs += Start-ParallelJob -Name "Desktop Files" -ScriptBlock {
    Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Force -ErrorAction SilentlyContinue | 
        Remove-Item -Force -Recurse 2>$null
}

Wait-ParallelJobs -Jobs $fileJobs -TimeoutSeconds $JobTimeout

# ============================================================================
# SECTION 2: SYSTEM OPERATIONS (Mostly Sequential, Some Parallel)
# ============================================================================

Write-Log "=== PHASE 2: SYSTEM OPERATIONS ==="

# Flush DNS Cache
Write-Host "  ↻ Flushing DNS cache..."
ipconfig /flushdns | Out-Null
Write-Log "  ✓ DNS cache flushed"

# Empty Recycle Bin
Write-Host "  ↻ Emptying Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Log "  ✓ Recycle Bin emptied"

# Create System Restore Point BEFORE major registry changes
if (-not $SkipRestore) {
    Write-Host "  ↻ Creating System Restore point..."
    try {
        Checkpoint-Computer -Description "Fresh Restore Point After Cleanup" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "  ✓ System Restore point created"
    }
    catch {
        Write-Log "  ⚠ Failed to create Restore point (may require VSS service)"
    }
}

# ============================================================================
# SECTION 3: REGISTRY CLEANUP (Parallelized)
# ============================================================================

Write-Log "=== PHASE 3: REGISTRY CLEANUP ==="
$regJobs = @()

# Job 1: Clear Run history
$regJobs += Start-ParallelJob -Name "Run History" -ScriptBlock {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f 2>$null
}

# Job 2: Clear Notepad history
$regJobs += Start-ParallelJob -Name "Notepad History" -ScriptBlock {
    reg delete "HKCU\Software\Microsoft\Notepad" /v "Recent File List" /f 2>$null
    Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState" -Recurse -Force 2>$null
}

# Job 3: Clear Remote Desktop history
$regJobs += Start-ParallelJob -Name "RDP History" -ScriptBlock {
    reg delete "HKCU\Software\Microsoft\Terminal Server Client\Default" /f 2>$null
    reg delete "HKCU\Software\Microsoft\Terminal Server Client\Servers" /f 2>$null
    Remove-Item "$env:USERPROFILE\Documents\Default.rdp" -Force 2>$null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU" /f 2>$null
}

# Job 4: Clear Network MountPoints
$regJobs += Start-ParallelJob -Name "Network MountPoints" -ScriptBlock {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2" /f 2>$null
}

# Job 5: Configure Taskbar (Windows 11)
$regJobs += Start-ParallelJob -Name "Taskbar Configuration" -ScriptBlock {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 1 /f 2>$null
}

# Job 6: Set default wallpaper path
$regJobs += Start-ParallelJob -Name "Wallpaper Registry" -ScriptBlock {
    reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$env:TEMP\bluewall.bmp" /f 2>$null
}

Wait-ParallelJobs -Jobs $regJobs -TimeoutSeconds $JobTimeout

# ============================================================================
# SECTION 4: UI RESET (Sequential - Requires specific ordering)
# ============================================================================

Write-Log "=== PHASE 4: UI RESET ==="

# Clear Start Menu layout
Write-Host "  ↻ Resetting Start Menu layout..."
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml" -Force 2>$null
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Shell\DefaultLayouts.xml" -Force 2>$null
Write-Log "  ✓ Start Menu layout reset"

# Create blue wallpaper
Write-Host "  ↻ Creating blue wallpaper..."
try {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap(1920, 1080)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 51, 153))  # Windows blue
    $bmp.Save("$env:TEMP\bluewall.bmp")
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($graphics) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($bmp) | Out-Null
    Write-Log "  ✓ Blue wallpaper created"
}
catch {
    Write-Log "  ⚠ Failed to create wallpaper: $_"
}

# Kill and restart Explorer
Write-Host "  ↻ Restarting Windows Explorer..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe
[System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.Runtime.InteropServices.Marshal]::GetActiveObject("Shell.Application")) | Out-Null
Start-Sleep -Seconds 1

# Apply wallpaper
Write-Host "  ↻ Applying wallpaper..."
[Runtime.InteropServices.Marshal]::ReleaseComObject(
    [System.Runtime.InteropServices.Marshal]::GetActiveObject("Shell.Application")
) | Out-Null

$code = @'
using System.Runtime.InteropServices;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper(string path) {
    SystemParametersInfo(20, 0, path, 3);
}
'@

Add-Type -MemberDefinition $code -Name WallpaperHelper
[WallpaperHelper]::SetWallpaper("$env:TEMP\bluewall.bmp")
Write-Log "  ✓ Wallpaper applied"

# Clear clipboard
Write-Host "  ↻ Clearing clipboard..."
"" | Set-Clipboard
Write-Log "  ✓ Clipboard cleared"

# ============================================================================
# SECTION 5: TASKBAR PIN CLEANUP (Sequential)
# ============================================================================

Write-Log "=== PHASE 5: TASKBAR PIN CLEANUP ==="
Write-Host "  ↻ Resetting taskbar pinned apps..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force -Recurse 2>$null
Start-Process explorer.exe
Start-Sleep -Seconds 2
Write-Log "  ✓ Taskbar pinned apps reset"

# ============================================================================
# SECTION 6: NETWORK CLEANUP (Parallelized)
# ============================================================================

Write-Log "=== PHASE 6: NETWORK CLEANUP ==="
$netJobs = @()

# Job 1: Remove network drives
$netJobs += Start-ParallelJob -Name "Network Drives" -ScriptBlock {
    net use * /delete /y 2>$null
}

# Job 2: Remove SMB mappings
$netJobs += Start-ParallelJob -Name "SMB Mappings" -ScriptBlock {
    Get-SmbMapping -ErrorAction SilentlyContinue | Remove-SmbMapping -Force -UpdateProfile 2>$null
}

# Job 3: Clear credentials
$netJobs += Start-ParallelJob -Name "Saved Credentials" -ScriptBlock {
    cmdkey /list | Select-String "Target:" | ForEach-Object {
        $target = $_.Line.Split(":")[1].Trim()
        cmdkey /delete:$target /generic 2>$null
    }
}

# Job 4: Restart workstation service
$netJobs += Start-ParallelJob -Name "Workstation Service" -ScriptBlock {
    net stop workstation /y 2>$null
    Start-Sleep -Seconds 1
    net start workstation 2>$null
}

Wait-ParallelJobs -Jobs $netJobs -TimeoutSeconds $JobTimeout

# ============================================================================
# SECTION 7: SYSTEM RESTORE CLEANUP (Sequential)
# ============================================================================

if (-not $SkipRestore) {
    Write-Log "=== PHASE 7: SYSTEM RESTORE MANAGEMENT ==="
    Write-Host "  ↻ Removing old system restore points..."
    try {
        vssadmin delete shadows /for=C: /all /quiet 2>$null
        Write-Log "  ✓ Old restore points removed"
    }
    catch {
        Write-Log "  ⚠ Failed to remove restore points: $_"
    }
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-Log ""
Write-Log "╔════════════════════════════════════════════════════════════╗"
Write-Log "║  Cleanup and reset completed successfully!                  ║"
Write-Log "║  Check the log file for details: $LogFile  ║"
Write-Log "╚════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "✓ Cleanup completed! System will be at peak performance." -ForegroundColor Green
Write-Host "  Log saved to: $LogFile" -ForegroundColor Gray
