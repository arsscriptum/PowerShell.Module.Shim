Shim Generator Module
=====================

A readme and issues list for Shim Generator Module (PowerShell.Module.Shim)
https://github.com/arsscriptum/PowerShell.Module.Shim.git

## What ?

Shimming is like symlinking, but it works much better. It's a form of redirection, where you create a "shim" that redirects input to the actual binary process and shares the output. It can also work to simply call the actual binary when it shims GUI applications.

This also allows applications and tools to be on the "PATH" without cluttering up the PATH environment variable.

I actually change my PATH variable on the cmdline, made a booboo and lost the previous value. All my PATH entries were lost.
Now, I only add the SHIM DIRECTORY in my path, and every program I want accessible, I create a shim.

Shimgen is a tool that makes batch redirection not suck so much by generating shims that point to target executable files.

* Provides an exe file that calls a target executable
* The exe can be called from powershell, bash, cmd.exe, or other shells just like you would call the target.
* Blocks and waits for command line apps to finish running, exits immediately when running a GUI app
* Uses the icon of the target if the target exists on creation
* Works better than symlinks. Symlinks on Windows fall down at file dependencies. So if your file depends on other files and DLLs, all of those need to also be linked.

## Shim Arguments

You pass these arguments to an executable that is a shim (e.g. executables in the bin directory of your choco install):

 * `--shimgen-help` - shows this help menu and exits without running the target
 * `--shimgen-log` - logging is shown on command line
 * `--shimgen-waitforexit` - explicitly tell the shim to wait for target to exit - useful when something is calling a gui and wanting to block - command line programs explicitly have waitforexit already set.
 * `--shimgen-exit` - explicitly tell the shim to exit immediately.
 * `--shimgen-gui` - explicitly behave as if the target is a GUI application. This is helpful in situations where the package did not have a proper .gui file.
 * `--shimgen-usetargetworkingdirectory` - set the working directory to the target path. Useful when programs need to be running from where they are located (usually indicates programs that have issues being run globally).
 * `--shimgen-noop` - Do not actually call the target. Useful to see what would happen if you ran the command.

## Benefits

These are the benefits of creating a shim:

Provides an exe file that calls a target executable.
Runs the target executable where it is, which means all dependencies and other things used are all in the original location
When items require elevated privileges, shims will raise UAC prompts.
The exe can be called from powershell, bash, cmd.exe, or other shells just like you would call the target.
Blocks and waits for command line apps to finish running, exits immediately when running a GUI app.
Uses the icon of the target if the target exists on creation.
Works better than symlinks. Symlinks on Windows fall down at file dependencies. So if your file depends on other files and DLLs, all of those need to also be linked.
Does not require special privileges like creating symlinks (symbolic links) do. So you can create shims without administrative rights.

## Setup 

Create a folder to store all your shims. Call 

```
Initialize-Shim 'C:\Programs\Shims\' -AddToPath
```

## Functionalities

#### New-Shim

New-Shim, default name for a exe:

```
New-Shim -t 'C:\Programs\AngryScanner\ipscan.exe'

Successfully created shim
Details:        ==>     c:\Programs\Shims\ipscan.exe    ==>     C:\Programs\AngryScanner\ipscan.exe
System Path Updated, type "ipscan' to run shim.
```


New-Shim, custom name for a exe:

```
New-Shim -target 'C:\Programs\AngryScanner\ipscan.exe' -name 's'

Successfully created shim
Details:        ==>     c:\Programs\Shims\s.exe    ==>     C:\Programs\AngryScanner\ipscan.exe
System Path Updated, type "s' to run shim.
```

#### Repair-AllShims

To re-create all shims from the registry

```
Repair-AllShims -Verbose

??????????????C:\Scripts\PowerShell\Cybercastor.PowerShell.Shim> Repair-AllShims
[OK]  araxis.exe
[OK]  compare.exe
[OK]  ConsoleCompare.exe
[OK]  gsudo.exe
[OK]  ipscan.exe
[OK]  Merge.exe
[OK]  speed.exe
[OK]  term.exe
[OK]  terminal.exe
[OK]  winterm.exe
[OK]  Done. 5 Shims in C:\Programs\Shims\
```

## Tests

#### RunTest.ps1

Run this to validate the scripts

## Contextual Menu

#### RunTest.ps1


## Tasks List
-------------
??? Install cmd
??? Initialize Module
??? New-Shim
??? Repair all shims
??? Remove Shim

Repository
----------

https://github.com/arsscriptum/PowerShell.Module.Shim.git



