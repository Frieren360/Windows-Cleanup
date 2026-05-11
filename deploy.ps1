& "$PSScriptRoot\config.bat"

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

        cmd /c $env:INSTALL_SCRIPT

        continue
    }

    # Remote machines
    ssh NETLAB@$pc "cmd /c $env:INSTALL_SCRIPT"
}
