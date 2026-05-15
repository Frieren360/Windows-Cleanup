# Parallelization Implementation

This document describes the parallel execution enhancements made to the Windows Cleanup script.

## Overview

The original `clean-fixed.bat` script has been refactored into a multi-threaded PowerShell implementation (`parallel-cleanup.ps1`) that executes independent operations concurrently, significantly improving overall execution time.

## Architecture

### Execution Phases

The cleanup process is organized into 6 distinct phases:

#### Phase 1: Pre-Cleanup System Restore Point (Sequential)
- Creates a system restore point before any cleanup begins
- Allows safe recovery if needed
- Can be skipped with `-SkipRestore` flag

#### Phase 2: File Cleanup (Parallel)
Runs 8 independent file cleanup jobs simultaneously:

1. **Clear-ExplorerRecent** - Windows File Explorer history
   - `%APPDATA%\Microsoft\Windows\Recent\*`
   - AutomaticDestinations and CustomDestinations

2. **Clear-WindowsTemp** - Temporary files
   - `%TEMP%\*`
   - `C:\Windows\Temp\*`

3. **Clear-Prefetch** - Prefetch files
   - `C:\Windows\Prefetch\*`

4. **Clear-EdgeData** - Microsoft Edge browser data
   - User Data, Crashpad, Temp directories
   - Kills Edge processes before deletion

5. **Clear-IconCache** - Icon and thumbnail cache
   - IconCache.db
   - Explorer icon cache files
   - Thumbnail cache files

6. **Clear-RecycleBin** - Empty Recycle Bin

7. **Clear-Desktop** - Remove desktop files

8. **Clear-NotepadHistory** - Clear Notepad history

#### Phase 3: Registry Cleanup (Parallel)
Runs 4 independent registry operations:

1. **Clear-RunHistory** - Run command history
2. **Clear-TaskbarSettings** - Taskbar configuration
3. **Clear-RDPHistory** - Remote Desktop history
4. **Clear-StartMenu** - Start Menu layout files

#### Phase 4: Network Operations (Parallel)
Runs 5 independent network cleanup jobs:

1. **Flush-DNSCache** - DNS cache flush
2. **Remove-MappedDrives** - Remove network drive mappings
3. **Clear-SMBMappings** - Clear SMB connections
4. **Clear-SavedCredentials** - Remove stored credentials
5. **Clear-NetworkCache** - Clear Windows network cache

#### Phase 5: System Optimization (Sequential)
- Clear clipboard
- Reset Taskbar pinned apps
- Set blue desktop wallpaper
- Restart Windows Explorer

#### Phase 6: Post-Cleanup System Restore Point (Sequential)
- Creates a fresh system restore point after successful cleanup
- Can be skipped with `-SkipRestore` flag

## Performance Improvements

### Expected Time Reduction

**Original Sequential Execution:**
- Estimated time: 5-10 minutes (depending on system load)
- Limited by slowest operation

**Parallel Execution:**
- Estimated time: 1.5-3 minutes
- Speedup factor: 3-5x
- Limited by slowest phase group (typically file I/O)

### Why Parallel Execution Helps

1. **Independent Operations** - File deletions, registry changes, and network operations don't depend on each other
2. **I/O Overlap** - While one job waits for disk I/O, others can execute
3. **CPU Utilization** - Modern systems can handle multiple operations simultaneously
4. **Reduced Wait Time** - Eliminates sequential bottlenecks

## Usage

### Basic Usage

```powershell
# Run with default settings
powershell -ExecutionPolicy Bypass -File parallel-cleanup.ps1
```

### Advanced Options

```powershell
# Skip system restore points
powershell -ExecutionPolicy Bypass -File parallel-cleanup.ps1 -SkipRestore

# Run in verbose mode
powershell -ExecutionPolicy Bypass -File parallel-cleanup.ps1 -Verbose

# Dry run (plan only, no execution)
powershell -ExecutionPolicy Bypass -File parallel-cleanup.ps1 -DryRun
```

### Using the Launcher

```powershell
# Launch with automatic update checking
powershell -ExecutionPolicy Bypass -File parallel-launcher.ps1

# Launch with options
powershell -ExecutionPolicy Bypass -File parallel-launcher.ps1 -SkipRestore -Verbose
```

## Logging and Monitoring

### Log Files

- **Main log:** `C:\ProgramData\Scripts\parallel-cleanup.log`
- **Job IDs:** Each parallel job is tracked with a unique ID
- **Timestamps:** Every operation is timestamped for audit purposes

### Log Format

```
[2026-05-15 14:30:45] [INFO] Windows Cleanup - Parallel Execution
[2026-05-15 14:30:45] [INFO] Maximum concurrent jobs: 8
[2026-05-15 14:30:46] [INFO] PHASE 1: Creating System Restore Point...
[2026-05-15 14:30:50] [INFO] System Restore point created successfully
[2026-05-15 14:30:50] [INFO] PHASE 2: Starting parallel file cleanup operations...
[2026-05-15 14:30:50] [DEBUG] Started job: Clear-ExplorerRecent (Job ID: 1)
```

### Job Monitoring

During execution, you can monitor job status in another PowerShell window:

```powershell
# View all running cleanup jobs
Get-Job | Where-Object {$_.Name -like "*Clear*" -or $_.Name -like "*Flush*"}

# View specific job status
Get-Job -Name "Clear-EdgeData"

# Receive job output
Receive-Job -Name "Clear-EdgeData"
```

## Job Concurrency Control

The script automatically limits concurrent jobs based on system capabilities:

```powershell
$MaxJobs = [System.Environment]::ProcessorCount
```

- **Quad-core system:** 4 concurrent jobs
- **Octa-core system:** 8 concurrent jobs
- **System automatically scales** to processor count

You can modify this in the script if needed:

```powershell
# To force a specific number of concurrent jobs
$MaxJobs = 4  # Set to desired value
```

## Dependencies and Constraints

### Sequential Dependencies

These operations **must run sequentially** (already handled in script):

1. **Before file cleanup:** Create restore point (Phase 1)
2. **Before Explorer operations:** Kill and restart Explorer (Phase 5)
3. **After cleanup:** Create restore point (Phase 6)

### System Requirements

- Windows 10 or later
- PowerShell 5.0 or later
- Administrator privileges
- Network access (optional, for remote deployment)

### I/O Considerations

**Note:** File deletion operations on the same disk may experience reduced parallelization benefit due to:
- Hard disk seeking limitations (HDD systems)
- I/O queue saturation
- Filesystem locking

**Recommendations:**
- SSD systems: Full parallelization benefit (3-5x speedup)
- HDD systems: Moderate benefit (2-3x speedup)

## Error Handling

### Graceful Failure

The script uses `ErrorActionPreference = 'SilentlyContinue'` to:
- Continue execution if one job fails
- Log all failures with details
- Report summary of succeeded/failed operations

### Error Recovery

If a cleanup operation fails:
1. Error is logged with timestamp
2. Other operations continue unaffected
3. System Restore point allows recovery
4. User can retry specific operations if needed

## Comparison: Original vs. Parallel

| Aspect | Original (Batch) | Parallel (PowerShell) |
|--------|------------------|----------------------|
| **Execution Type** | Sequential | Concurrent |
| **Languages Used** | Batch, PowerShell, VBScript | Pure PowerShell |
| **Estimated Time** | 5-10 minutes | 1.5-3 minutes |
| **CPU Utilization** | Single-threaded (1 core) | Multi-threaded (N cores) |
| **Logging** | Basic | Comprehensive with job tracking |
| **Error Handling** | Limited | Robust with job tracking |
| **Maintainability** | Moderate | High (PowerShell) |
| **Scalability** | Fixed execution flow | Adaptive to system resources |

## Future Enhancements

Potential improvements for future versions:

1. **Progress Bar** - Real-time progress indication
2. **Selective Cleanup** - Allow users to choose which operations to run
3. **Configuration Profiles** - Different cleanup levels (Light/Medium/Full)
4. **Pre-flight Checks** - Validate permissions before execution
5. **Email Notifications** - Send completion report via email
6. **Performance Metrics** - Measure time saved and disk space freed
7. **Rollback Support** - Automatic rollback on critical errors
8. **Web Dashboard** - Monitor remote machine cleanups

## Troubleshooting

### Jobs Hanging

If jobs appear to hang:

```powershell
# Check running jobs
Get-Job

# Stop specific job
Stop-Job -Name "Clear-EdgeData"

# Remove all jobs
Remove-Job -State Completed,Failed
```

### Permission Denied Errors

Ensure running as Administrator:
```powershell
Start-Process powershell -Verb RunAs
```

### Explorer Won't Restart

Manually restart:
```powershell
Start-Process explorer.exe
```

## Contact and Support

For issues or suggestions related to the parallelization implementation, please:
1. Check the log file: `C:\ProgramData\Scripts\parallel-cleanup.log`
2. Review the error messages with timestamps
3. Open an issue on the GitHub repository

## References

- PowerShell Jobs: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_jobs
- Error Handling: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_error_handling
