@echo off

call config.bat

for /f "delims=" %%A in pcs.txt do (
  Invoke-Command -ComputerName %%A -ScriptBlock { cmd.exe /c "\\192.168.5.253\storage\cleanup-script\clean-fixed.bat" }
)
