Shim Generator Module
=====================

A readme and issues list for Shim Generator Module (PowerShell.Module.Shim)
https://github.com/arsscriptum/PowerShell.Module.Shim.git



The other day, I needed to run an executable I just downloaded but it was not in my PATH. So I quickly changed my ```PATH``` variable and made a mistake doing so, hence I needed to recreate my ```PATH``` variable and this was a pain!
From there, I decided to create a module to make executables shims for programs that are not in the ```PATH```. All the shims will be in the same directory and that directory added to my ```PATH```.

You ask: *What is a shim ?*
Shimming is like symlinking, but it works much better. It's a form of redirection, where you create a "shim" that redirects input to the actual binary process and shares the output. It can also work to simply call the actual binary when it shims GUI applications.

We like to call this "batch redirection that works".

This also allows applications and tools to be on the "PATH" without cluttering up the PATH environment variable.

So when you create a shim, you create an executable that starts the target program

---------------------------------------------------------------------------------------------------------

<h4> Benefits </h4>

These are the benefits of creating a shim:

<ul>
<li> Provides an exe file that calls a target executable.</li>
<li> Runs the target executable where it is, which means all dependencies and other things used are all in the original location</li>
<li> When items require elevated privileges, shims will raise UAC prompts.</li>
<li> The exe can be called from powershell, bash, cmd.exe, or other shells just like you would call the target.</li>
<li> Blocks and waits for command line apps to finish running, exits immediately when running a GUI app.</li>
<li> Uses the icon of the target if the target exists on creation.</li>
<li> Works better than symlinks. Symlinks on Windows fall down at file dependencies. So if your file depends on other files and DLLs, all of those need to also be linked.</li>
<li> Does not require special privileges like creating symlinks (symbolic links) do. So you can create shims without administrative rights.</li>
</ul>

---------------------------------------------------------------------------------------------------------

<h4> Usage </h4>

Our Shim module is simple and contains the following functions:

<ul>
<li> Initialize-ShimModule </li>
<li> New-Shim </li>
<li> Remove-Shim </li>
<li> Repair-AllShims </li>
</ul>


<h4> How does it work? </h4>

Our module uses a tool from [Chocolatey](https://docs.chocolatey.org/en-us) called ```ShimGen``` that inspects an executable and creates a small binary, known as a "shim", that simply calls the executable. Out module calls this
program to create the shim and then it places that shim in the "$($env:ShimsPath)". It creates the shim by generating it at runtime based on the actual binary's information.

--------------------------------------------------------------------------------------------------------

<h4> Initialize-ShimModule </h4>

This function Initializes all the variables and directories required to create and store shims. Basically, it will check for the location of the ```shimgen.exe``` program, and create 
a directory where the shims will be located. Also, it will add this directory to the users ```PATH``` 


```powershell
	function Initialize-ShimModuleWithDefault{
	    [CmdletBinding(SupportsShouldProcess)]
	    param()

	    $ShimPath = "C:\Programs\Shims\"
	    New-Item -Path $ShimPath -ItemType Directory -Force -ErrorAction Ignore | Out-null
	    Write-Host -ForegroundColor DarkGreen "Initialize-ShimModule -Path `"$ShimPath`" -ShimGenPath `"C:\ProgramData\chocolatey\tools\shimgen.exe`""
	    Initialize-ShimModule -Path "$ShimPath" -ShimGenPath "C:\ProgramData\chocolatey\tools\shimgen.exe"
	}


	function Initialize-ShimModule{
	<#
	    .Synopsis
	       Setup the shim system. Needs to be run only once
	    .Description
	       Setup the shim system by creating the registry keys, add a PATH entry

	    .Parameter Path
	       Path where we store all the shims 

	    .Example
	       Initialize-ShimModule -Path 'c:\Programs\Shims'
	#>

	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [ValidateScript({
	            if(-Not ($_ | Test-Path) ){
	                throw "ValidateScript Path => File or folder does not exist"
	            }
	            if(-Not ($_ | Test-Path -PathType Container) ){
	                throw "ValidateScript Path => The Path argument must be a Directory. Files paths are not allowed."
	            }
	            return $true 
	        })]
	        [Parameter(Mandatory=$true,Position=0)]
	        [String]$Path,
	        [ValidateScript({
	            if(-Not ($_ | Test-Path) ){
	                throw "ValidateScript ShimGenPath => File or folder does not exist"
	            }
	            if(-Not ($_ | Test-Path -PathType Leaf) ){
	                throw "ValidateScript ShimGenPath => The Path argument must be a executable."
	            }
	            return $true 
	        })]        
	        [Parameter(Mandatory=$false,Position=1)]
	        [String]$ShimGenPath,
	        [Parameter(Mandatory=$false)]
	        [switch]$AddToPath
	    )

	    # throw errors on undefined variables
	    Set-StrictMode -Version 1

	    # stop immediately on error
	    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

	    if ($Path -notmatch '\\$'){
	        $Path += '\'
	    }
	    try {
	        $null=New-Item (Get-ShimModuleRegistryPath) -Force
	        $null=New-RegistryValue (Get-ShimModuleRegistryPath) "shims_location" $Path "string"      
	        $null=New-RegistryValue (Get-ShimModuleRegistryPath) "shimgen_exe_path" 'temp' "string"
	        $null=New-RegistryValue (Get-ShimModuleRegistryPath) "initialized" 1 "DWORD"
	        $ShimGenPath = Get-ShimGenExePath 

	        $null=New-RegistryValue (Get-ShimModuleRegistryPath) "shimgen_exe_path" "$ShimGenPath" "string"

	        if($AddToPath){
	          Write-Output "Setup: add to system path"
	          $Env:Path += ";$ShimLocation"
	        }
	        Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
	        Write-Host "ShimGen Path set to $ShimGenPath"  
	        Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
	        Write-Host "Shims location set to $Path"  

	        [Environment]::SetEnvironmentVariable("ShimsPath","$ShimLocation",[EnvironmentVariableTarget]::User)
	    }
	    catch{
	        Show-ExceptionDetails($_) -ShowStack
	    }

	}
```

--------------------------------------------------------------------------------------------------------

<h4> New-Shim </h4>

Add a Shim entry in the Registry, create the shim to the target

```powershell
    function New-Shim{
        <#
          .Synopsis
             Add a Shim entry in the Registry, create the shim to the target
          .Description
             Add a Shim entry in the Registry, create the shim to the target Takes the
             name of the target by default, optionaly you can specify a shim name.

          .Parameter Target
             Target Executable
          .Parameter Name
             The Name of the shim

          .Example
             Add-Shim "c:\Program Files\Visual Studio\Tools\makehn.exe"
             Add-Shim "c:\sysinternals\pslist.exe" -Name "listprocesses.exe"
        #>
        [CmdletBinding(SupportsShouldProcess=$true)]
        param (
         [parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]$Target,
         [parameter(Mandatory=$false)]
         [ValidateNotNullOrEmpty()]$Name,
         [parameter(Mandatory=$false)]
         [switch]$Force     
        )

        $Init = Get-IsShimInitialized
        if ( $Init -eq $False ) { throw 'not initialized'; return $false ;}
        $ShimGenExe=Get-ShimGenExePath
        $RegBasePath = (Get-ShimModuleRegistryPath)
        Write-Verbose "ShimGenExePath $ShimGenExe"
        if(-not(Test-Path $ShimGenExe)){
            Write-Error 'could not find shimgen.exe'
                return
        }
        $ShimLocation=Get-ShimLocation
        Write-Verbose "ShimLocation $ShimLocation"
        if(-not(Test-Path $ShimLocation)){
            throw 'could not find Shim location'

        }

        $Target = (Resolve-Path -Path $Target).Path
        Write-Verbose "Target $Target"
        if(-not(Test-Path $Target)){
            throw 'No such target' 
        }

        if ($ShimLocation -notmatch '\\$'){
            $ShimLocation += '\'
        }

        $Sfix = '.exe'
        if($Name -eq $null -Or $Name -eq ""){
            $Sfix=(Get-Item $Target).Extension
            $Name=(Get-Item $Target).BaseName + $Sfix
        }
        try {

             $ShimFullPath = $ShimLocation + $Name
            if($Force){        
                $removed = Remove-Item -Path $ShimFullPath -Force -ErrorAction Ignore
            }
            Write-Verbose "Add-Shim: name is $ShimFullPath"
           


            Write-Log "Creating new shim"

            $exists1=Test-RegistryValue "$RegBasePath\$Name" 'target'
            $exists2=Test-RegistryValue "$RegBasePath\$Name" 'shim'
            if($exists1 -or $exists2){
                Write-Log  "shim already exists, delete before adding. Use -Force or See Remove-Shim"
                throw 'shim already exists, delete before adding. See "Remove-Shim"'
                return
            }
            Write-Verbose "New-Shim: $ShimFullPath"

            $Res = Test-Path $ShimFullPath
            if($Res -eq $true){
                 Write-Log  "ALREADY EXISTS : $ShimFullPath"
                 throw  "ALREADY EXISTS : $ShimFullPath"
                 return $null
            }
            Write-Log "$ShimFullPath ==> $Target"

            $Res = Invoke-ShimGenProgram $ShimFullPath $Target
            if($Res -eq $False){
                 Write-Log  "FAILURE : Invoke-ShimGenProgram $ShimFullPath $Target"
                 throw "FAILURE : Invoke-ShimGenProgram $ShimFullPath $Target"
                 return $null
            }
            $Res = Test-Path $ShimFullPath
            if($Res -eq $False){
                 Write-Log  "NOT FOUND : $ShimFullPath"
                 throw  "NOT FOUND : $ShimFullPath"
                 return $null
            }
            [pscustomobject]$Obj = @{
                'target' = $Target 
                'shim'   = $ShimFullPath
            }


            if($Res -eq $True){
              $null=New-RegistryValue "$RegBasePath\$Name" 'target' $Target "string"
              $null=New-RegistryValue "$RegBasePath\$Name" 'shim'   $ShimFullPath "string"
              Write-Log "Successfully created shim"
              Write-Log "type '$Name' to run program."
              return $ShimFullPath
            }
        }
        catch{
            Show-ExceptionDetails($_) -ShowStack
        }
    }

```


--------------------------------------------------------------------------------------------------------


<h4> Remove-Shim </h4>

Removes a shim by deleting the executable in the shim directory and removing the entry in the registry.


```powershell
    function Remove-Shim{

        [CmdletBinding(SupportsShouldProcess=$true)]
        param (
         [parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]$Name
        )
        try{
            if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}

            $RegBasePath = (Get-ShimModuleRegistryPath)
            $DoneNoError = $True
            if($Name -ne ''){
                $ShimLocation=Get-ShimLocation
                Write-Verbose "ShimLocation $ShimLocation"
                if(-not(Test-Path $ShimLocation)){
                    throw 'could not find Shim location'

                }
                $ShimFullPath = $ShimLocation + $Name
                if ($ShimFullPath.get_Length() -gt 4)
                {
                    $lastchars=$ShimFullPath.Substring($ShimFullPath.get_Length()-4)
                    if($lastchars -notmatch ".exe")
                    {
                         $ShimFullPath += '.exe'
                    }
                }
                Write-Verbose "ShimFullPath $ShimFullPath"
                $RegBasePath = "$RegBasePath\$Name"
                Remove-Item -Path $RegBasePath -Force -recurse -ErrorAction Ignore | Out-null
       
                Remove-Item -Path $ShimFullPath -Force -ErrorAction Stop | Out-null
                  
            }
        }catch{
            $DoneNoError = $false
        }
        finally{
            if($DoneNoError ){
              Write-Host -ForegroundColor DarkGreen "[DONE] " -NoNewline
              Write-Host " Remove-Shim completed" -ForegroundColor DarkGray      
            }else{
                Write-Host -ForegroundColor DarkRed "[ ERROR ] " -NoNewline
                Write-Host " no such shim " -ForegroundColor DarkYellow 
            }
      }

      return $DoneNoError
    }
```

--------------------------------------------------------------------------------------------------------



<h4> Repair-AllShims </h4>

Will rebuild all shims from the registry entries. This is useful in the case where you deleted the shims by mistake. 


```powershell
  function Repair-AllShims{
  <#
      .Synopsis
         Update all the shims on disk using the entries backed up in the registry
      .Description
         Update all the shims on disk using the entries backed up in the registry
  #>
      [CmdletBinding(SupportsShouldProcess=$true)]
      param ()
      $Init = Get-IsShimInitialized
      #if ( $Init -eq $False ) { throw 'not initialized'; return $false ;}
      $Script:StepNumber = 0
      $Script:TotalSteps = 1
      $Script:ProgressMessage = "REPAIRING ALL SHIMS..."
      $Script:ProgressTitle = "REPAIRING ALL SHIMS..."
      Invoke-AutoUpdateProgress_Shim  
      
      # throw errors on undefined variables
      Set-StrictMode -Version 1

      # stop immediately on error
      $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

      try {
          $ShimGenExe=Get-ShimGenExePath
          if(-not(Test-Path $ShimGenExe)){
            Write-Error "could not find shimgen.exe $ShimGenExe"
              return
          }
          $RegBasePath = (Get-ShimModuleRegistryPath)
       
          
          $AllShimEntries=(Get-Item "$RegBasePath\*").PSChildName
          $count=$AllShimEntries.Count
          Write-Verbose "Repair-AllShims: get entries in $RegBasePath* : $count"
          $Script:StepNumber = 0
          $Script:TotalSteps = $count
          $TargetPath = 
          
          foreach($Shim in $AllShimEntries){
              Invoke-AutoUpdateProgress_Shim
              $Script:ProgressMessage = "Reset shim $Shim ($Script:StepNumber / $Script:TotalSteps)"
            $targetexists=Test-RegistryValue "$RegBasePath\$Shim" 'target'
            $shimexists=Test-RegistryValue "$RegBasePath\$Shim" 'shim'
            if($targetexists -and $shimexists){
                
              $Target=(Get-ItemProperty "$RegBasePath\$Shim").Target
              $Shim=(Get-ItemProperty "$RegBasePath\$Shim").Shim

              Remove-Item -Path $Shim -Force -ErrorAction Ignore | Out-null
              New-Item -Path $Shim -ItemType File -Force -ErrorAction Ignore | Out-null
              $Fullname = (Get-Item  -Path $Shim).Fullname
              Remove-Item -Path $Shim -Force -ErrorAction Ignore | Out-null
              Invoke-ShimGenProgram -Name $Fullname -Target $Target | Out-null
              Sleep 1
              
            }
            
          }
          
      

      }catch{
        Show-ExceptionDetails($_) -ShowStack
      }
      finally{
        Write-Host -ForegroundColor DarkGreen "[DONE] " -NoNewline
        Write-Host " Repair-AllShims completed" -ForegroundColor DarkGray
        $ShimLocation = Get-ShimLocation
        $Files = (gci -Path $ShimLocation -File -Filter '*.exe').Fullname
        foreach($f in $Files){
          Write-Host -ForegroundColor DarkRed "[Shim] " -NoNewline
          Write-Host "$f" -ForegroundColor DarkYellow
        }
    }
  }
```


--------------------------------------------------------------------------------------------------------


<h4> Install the contextual menu actions </h4>

There's a script that you can use to create contextual menu actions to Add a new shim and remove others. This is optional and meant as a shortcut only.


```powershell
    .\Install-Menu.ps1
```

<img class="card-img-top-restricted-60"
     src="/assets/img/posts/shimming/2.png"
     alt="Contextual Menu" />



## Tasks List
-------------
龱 Install cmd
龱 Initialize Module
龱 New-Shim
龱 Repair all shims
龱 Remove Shim

Repository
----------

https://github.com/arsscriptum/PowerShell.Module.Shim.git



