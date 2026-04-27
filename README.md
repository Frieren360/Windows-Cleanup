This script pulls the script from a remote location and stores it locally on a computer. If network is not available, it will just run the script, else check for an updated version from the server.

Run install.bat as administrator to install files to C:\ProgramData\Scripts\

Alternatively for a manual install:
Put the .bat files and .vbs file in C:\ProgramData\Scripts\

And run launcher.vbs with wscript.exe in task scheduler. You can just import the .xml file into task scheduler to automatically do this.