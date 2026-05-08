$pcs = Get-Content ".\pcs.txt"

foreach ($pc in $pcs) {
    ssh NETLAB@$pc "cmd /c \\192.168.5.253\storage\cleanup-script\install.bat"
}
