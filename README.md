# Windows Cleanup Script User Guide

A comprehensive Windows system cleanup utility that removes temporary files, cache data, and clears various system artifacts to reclaim disk space and improve system privacy. The script can be run locally or deployed to multiple machines remotely.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Remote Deployment](#remote-deployment)
- [What Gets Cleaned](#what-gets-cleaned)
- [System Requirements](#system-requirements)

## Overview

This cleanup script performs a deep system clean of your Windows machine. It can:

- Run locally on a single machine with automatic update checking
- Be deployed across multiple remote machines using SSH
- Pull script updates from a network source if available
- Log all cleanup operations to a file for audit purposes

The script runs as a scheduled task and handles network availability gracefully. If your network is unavailable, it will execute the cached local copy. When network is available, it checks for and downloads any updated versions.

## Installation

### Quick Install (Recommended)

1. Download all repository files to your computer
2. Open PowerShell as Administrator
3. Navigate to the folder containing the files
4. Run the following command:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

This will automatically:
- Create the installation directory at `C:\ProgramData\Scripts\`
- Copy all script files (.bat, .ps1, .vbs) to the installation directory
- Create scheduled tasks by importing the XML configuration files

### Manual Install

If you prefer to install manually:

1. Create the folder `C:\ProgramData\Scripts\` if it does not already exist
2. Copy all `.bat` files to `C:\ProgramData\Scripts\`
3. Copy all `.ps1` files to `C:\ProgramData\Scripts\`
4. Copy the `.vbs` file to `C:\ProgramData\Scripts\`
5. Open Task Scheduler and import the `.xml` file to create the scheduled task
   - Alternatively, run `launcher.vbs` with `wscript.exe` through Task Scheduler manually

## Configuration

Before running the script, configure your settings in the `config.ps1` file:

```powershell
# Host Machine IP address (used for remote deployment)
$HOST_MACHINE = ""

# Directory where this script lives
$SCRIPT_DIR = $PSScriptRoot

# Location of the main cleanup script
$SOURCE = Join-Path $SCRIPT_DIR "clean-fixed.bat"

# Location of the installer script
$INSTALL_SOURCE = Join-Path $SCRIPT_DIR "install.ps1"

# Where to install files on local and remote machines
$DEST_DIR = "C:\ProgramData\Scripts"

# Where to save operation logs
$LOG_FILE = "C:\ProgramData\Scripts\run.log"
```

### Key Configuration Options

**HOST_MACHINE**: Set this to your machine's IP address if you plan to use the remote deployment script. This ensures your local machine is treated correctly in the deployment process.

**DEST_DIR**: The target installation directory. Default is `C:\ProgramData\Scripts\`, which requires administrator privileges but is the recommended location.

**LOG_FILE**: All cleanup operations are logged here for review. Check this file to see what was cleaned and when.

## Usage

### Local Use

Once installed, the cleanup task will run automatically according to the schedule defined in the imported XML file. You can also manually run the cleanup:

1. Open Task Scheduler
2. Find the task imported from the XML file
3. Right-click and select "Run"

Or run directly from PowerShell:

```powershell
& "C:\ProgramData\Scripts\launcher.ps1"
```

### How It Works

The `launcher.ps1` script:

1. Loads your configuration from `config.ps1`
2. Checks if a local copy of the cleanup script exists
3. If no local copy exists, downloads it from the network source
4. If a local copy exists, compares timestamps to check for updates
5. Downloads any newer version from the network
6. Executes the cleanup script and logs the results

This approach allows the script to work offline with cached copies while staying up-to-date when network access is available.

## Remote Deployment

You can deploy the cleanup script to multiple machines across your network.

### Prerequisites

- SSH must be installed on your machine and all target machines
- Port 22 must be open on all remote machines
- You must have SSH credentials for connecting to remote machines
- All machines must have PowerShell available

### Setting Up Remote Machines

1. Create a file named `pcs.txt` in the same directory as the scripts
2. Add one machine per line using SSH remote node syntax:

```
USER@MACHINE
```

You can specify machines by IP address or hostname, with or without username:

```
192.168.0.12
USER@192.168.0.11
local-machine-hostname
USER@local-machine.example.com
```

You can also include additional SSH command-line options on each line if needed.

### Configure Your Host Machine

Update `config.ps1` and set `$HOST_MACHINE` to your machine's IP address. When you run the deployment script, it will detect this and install locally instead of using SSH, which is more efficient.

Example:

```powershell
$HOST_MACHINE = "192.168.0.100"
```

### Run Deployment

From PowerShell as Administrator, run:

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

The script will:

1. Read the list of machines from `pcs.txt`
2. Skip the host machine listed in config.ps1 and install locally instead
3. Use SSH to connect to each remote machine
4. Run the installation script on each remote machine
5. Report the results for each machine

## What Gets Cleaned

### Removed Files and Data

The cleanup script removes the following items:

**General System Cleanup**
- Windows File Explorer history
- Temporary files (Windows Temp and System Temp folders)
- Prefetch files
- DNS Cache
- Run history
- Clipboard contents
- Taskbar pinned apps
- Recycle Bin contents
- Desktop files
- System Restore points
- Desktop icon cache and layout

**Browser Data (Microsoft Edge)**
- Edge user profiles
- Browsing data and history
- Edge cache leftovers

**Network**
- Mapped network drives
- Active SMB connections
- Saved network credentials from Credential Manager
- Windows network cache
- Remote Desktop connection history

### System Optimization

The script also performs these system optimization tasks:

- Resets the Start Menu layout to defaults
- Resets icon layout
- Sets a blank blue desktop wallpaper
- Creates a fresh System Restore point before cleanup begins

## System Requirements

- Windows 10 or later
- Administrator privileges (required for accessing system files and Task Scheduler)
- PowerShell 5.0 or later
- For remote deployment: SSH installed and port 22 open on all machines
- Disk space: Minimal. The script only removes files, it does not install additional software

## Troubleshooting

### Installation Fails

Ensure you are running PowerShell as Administrator. Right-click PowerShell and select "Run as Administrator".

### Script Doesn't Run on Schedule

1. Open Task Scheduler
2. Check that the imported tasks are enabled
3. Verify that the task has appropriate permissions to run
4. Check the log file at `C:\ProgramData\Scripts\run.log` for errors

### SSH Deployment Fails

1. Verify SSH is installed: `ssh -V` in PowerShell
2. Test connectivity: `ssh USER@MACHINE "echo test"`
3. Ensure port 22 is open on target machines
4. Check that `pcs.txt` uses correct syntax
5. Verify credentials in `pcs.txt` are correct

### Permissions Issues

All operations require Administrator privileges. If you encounter "Access Denied" errors, re-run the installation and execution with an Administrator PowerShell window.
