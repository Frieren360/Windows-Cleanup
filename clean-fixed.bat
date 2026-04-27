@echo off
title Windows Cleanup + UI Reset

echo Cleaning Windows File Explorer history...

:: Clear File Explorer Recent Files
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*"

:: Clear AutomaticDestinations (Quick Access history)
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*"

:: Clear CustomDestinations
del /f /q "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*"


echo Clearing Temp files...

:: Clear Windows Temp
set "SCRIPTPATH=%~f0"

for %%f in ("%TEMP%\*") do (
    if /i not "%%~ff"=="%SCRIPTPATH%" del /f /q "%%~ff"
)

for /d %%d in ("%TEMP%\*") do (
    rd /s /q "%%~fd"
)

:: Clear System Temp
del /f /s /q "C:\Windows\Temp\*"


echo Clearing Prefetch...

del /f /s /q "C:\Windows\Prefetch\*"


echo Flushing DNS cache...

ipconfig /flushdns


echo Closing Microsoft Edge...

taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im msedgewebview2.exe >nul 2>&1

echo Removing Edge profiles and browsing data...

rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data"


echo Clearing Edge cache leftovers...

rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\Crashpad"
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\Temp"


echo Cleaning Run history...

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f


echo Clearing clipboard...

echo off | clip


echo Resetting Taskbar pinned apps...

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 5 >nul
del /f /q "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*"


echo Resetting Start Menu layout...

del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml"
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Shell\DefaultLayouts.xml"


echo Resetting Desktop icon cache and layout...

del /f /q "%LOCALAPPDATA%\IconCache.db"
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*"
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache*"

echo Clearing Notepad history...

:: Classic Notepad
reg delete "HKCU\Software\Microsoft\Notepad" /v Recent File List /f >nul 2>&1

:: Modern Notepad (Windows 11)
rd /s /q "%LOCALAPPDATA%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState"


echo Emptying Recycle Bin...

powershell -command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"


echo Removing all files from Desktop...

:: Delete desktop files
del /f /s /q "%USERPROFILE%\Desktop\*"

:: Delete desktop folders
for /d %%x in ("%USERPROFILE%\Desktop\*") do rd /s /q "%%x"


echo Setting blank blue desktop wallpaper...

:: Create a blue wallpaper
powershell -command "Add-Type -AssemblyName System.Drawing; $bmp = New-Object System.Drawing.Bitmap 1920,1080; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.Clear([System.Drawing.Color]::FromArgb(0,102,204)); $bmp.Save($env:TEMP + '\bluewall.bmp');" $g.Clear([Drawing.Color]::FromArgb(0,102,204)); $bmp.Save($env:TEMP + '\bluewall.bmp');"

:: Apply wallpaper
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%TEMP%\bluewall.bmp" /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters


echo Centering Start Menu and taskbar icons...

:: Windows 11 taskbar alignment
:: 0 = left, 1 = center
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 1 /f


echo Restarting Explorer...

cmd /c start "" explorer.exe


echo Clearing all System Restore points...

:: Delete all shadow copies (removes all restore points)
vssadmin delete shadows /for=C: /all /quiet


echo Creating fresh System Restore point...

powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Fresh Restore Point After Cleanup' -RestorePointType MODIFY_SETTINGS"


echo.
echo Cleanup and reset completed successfully.
pause