@echo off

call config.bat

psexec @pcs.txt -s -d cmd /c "%SOURCE%"
