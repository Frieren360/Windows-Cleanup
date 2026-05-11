. "$PSScriptRoot\config.ps1"

$pcs = Get-Content ".\pcs.txt"

foreach ($pc in $pcs) {

    # Skip blank lines
    if ([string]::IsNullOrWhiteSpace($pc)) {
        continue
    }

    $pc = $pc.Trim()

    # Run locally on host machine
    if ($pc -eq $env:HOST_MACHINE) {

        Write-Host "Running locally on host machine: $pc"

        & "$env:INSTALL_SOURCE"

        continue
    }

    # Remote machines
    ssh NETLAB@$pc "& $env:INSTALL_SOURCE"
}
