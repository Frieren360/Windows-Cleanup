. "$PSScriptRoot\config.ps1"

$pcs = Get-Content ".\pcs.txt"

foreach ($pc in $pcs) {

    # Skip blank lines
    if ([string]::IsNullOrWhiteSpace($pc)) {
        continue
    }

    $pc = $pc.Trim()

    # Run locally on host machine
    if ($pc -eq $HOST_MACHINE) {

        Write-Host "Running locally on host machine: $pc"

        & "$INSTALL_SOURCE"

        continue
    }

    # Remote machines
    ssh NETLAB@$pc "powershell -NoProfile -ExecutionPolicy Bypass -File `"$INSTALL_SOURCE`""
}

Read-Host "Press Enter to exit"
