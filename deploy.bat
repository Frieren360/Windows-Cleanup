@echo off

call config.bat

psexec @pcs.txt -s -d cmd /c "\\192.168.5.253\storage\Windows-Cleanup\install.bat"
