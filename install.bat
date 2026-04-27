@echo off
setlocal

REM Source directory (where this script is run)
set "SRC=%~dp0"

REM Destination directory
set "DEST=C:\ProgramData\Scripts"

echo Creating destination directory if it doesn't exist...
if not exist "%DEST%" (
    mkdir "%DEST%"
)

echo.
echo Copying .bat and .vbs files...
copy "%SRC%*.bat" "%DEST%" /Y >nul
copy "%SRC%*.vbs" "%DEST%" /Y >nul

echo.
echo Importing scheduled tasks from XML files...

for %%F in ("%SRC%*.xml") do (
    echo Importing task from %%~nxF ...
    
    REM Use filename (without extension) as task name
    set "TASKNAME=%%~nF"
    
    call schtasks /create /tn "%%~nF" /xml "%%F" /f
)

echo.
echo Installation complete.
pause