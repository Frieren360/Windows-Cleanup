& "$PSScriptRoot\config.bat"

$pcs = Get-Content ".\pcs.txt"

foreach ($pc in $pcs) {

    # Skip blank lines
    if ([string]::IsNullOrWhiteSpace($pc)) {
        continue
    }

    # Skip host machine
    if ($pc.Trim() -eq $env:HOST_MACHINE) {
        Write-Host "Skipping host machine: $pc"
        continue
    }

    ssh NETLAB@$pc "cmd /c \\192.168.5.253\storage\cleanup-script\install.bat"
}
