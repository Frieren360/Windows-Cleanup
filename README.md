This script pulls the script from a remote location and stores it locally on a computer. If network is not available, it will just run the script, else check for an updated version from the server.

Run install.ps1 as administrator to install files to `C:\ProgramData\Scripts\`

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

Alternatively for a manual install:
Put the `.bat` files, the `.ps1` files and `.vbs` file in `C:\ProgramData\Scripts\`

And run `launcher.vbs` with `wscript.exe` in task scheduler. You can just import the `.xml` file into task scheduler to automatically do this.

To deploy the script, make sure SSH is installed and that port 22 on each machine is open and run the `deploy.ps1` file.

```powershell
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

To add remote machines to deploy to, create a new line inside pcs.txt following ssh remote node syntax:

```
USER@MACHINE
```

For example:

```
192.168.0.12
USER@192.168.0.11
```

# Configuration
To configure options, edit the file `config.ps1`.
HOST_MACHINE efers to the main computer that the script is being deployed from and will locally install instead of being deployed via ssh when running `deploy.ps1 `.
