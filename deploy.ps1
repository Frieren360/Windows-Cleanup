Set-Location $PSScriptRoot
& "$PSScriptRoot\config.bat"

$pcs = Get-Content ".\pcs.txt"

foreach ($pc in $pcs) {

    if ([string]::IsNullOrWhiteSpace($pc)) { continue }

    $pc = $pc.Trim()

    if ($pc -eq $env:HOST_MACHINE) {

        Write-Host "Running locally on host machine: $pc"
        cmd.exe /c "$env:INSTALL_SCRIPT"

        continue
    }

    ssh NETLAB@$pc "cmd /c $env:INSTALL_SCRIPT"
}
