<#̷#̷\
#̷\ 
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#̷\ 
#̷##>


function Get-ShimModuleRegistryPath { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    $Path = "$ENV:OrganizationHKCU\$ModuleName"
   
    return $Path
}
function Get-ShimGenExePath{
    [cmdletbinding()]
    Param()
    $Exists=Test-RegistryValue (Get-ShimModuleRegistryPath) "shimgen_exe_path"
    if($Exists){
        $ShimGenExe=Get-RegistryValue (Get-ShimModuleRegistryPath) "shimgen_exe_path"
        if(Test-Path $ShimGenExe -EA Ignore){
          return $ShimGenExe  
        }    
    }
    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}
    $Cmd =  Get-Command 'shimgen.exe' -ErrorAction Ignore
    if($Cmd -ne $null){
       $ShimGenExe = $Cmd.Source
       return $ShimGenExe  
    }
    
    $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
    $Dir = (Get-Item $ScriptMyInvocation).DirectoryName
    $ShimGenExe = Join-Path $Dir 'bin\shimgen.exe'
    return $ShimGenExe
}


function Invoke-Process {               # NOEXPORT
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]$FilePath,
        [Parameter(Mandatory = $True)]
        [string[]]$ArgumentList,
        [Parameter(Mandatory = $False)]
        [string]$WorkingDirectory
    )
    $ErrorActionPreference = 'Stop'

    if(($WorkingDirectory -eq $null) -Or ($WorkingDirectory.Length -eq 0)){
        $WorkingDirectory=(Get-Location).Path
    
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $Guid=$(( New-Guid ).Guid)  
        $FNameOut=$env:Temp + "\InvokeProcessOut"+$Guid.substring(0,4)+".log"
        $FNameErr=$env:Temp + "\InvokeProcessErr"+$Guid.substring(0,4)+".log"

        $startProcessParams = @{
            FilePath               = $FilePath
            RedirectStandardError  = $FNameErr
            RedirectStandardOutput = $FNameOut
            Wait                   = $true
            PassThru               = $true
            NoNewWindow            = $true
            WorkingDirectory       = $WorkingDirectory
        }

        $cmdName=""
        $cmdId=0
        $cmdExitCode=0

        $proc = Start-Process @startProcessParams -ArgumentList $ArgumentList
        #Write-Host "RetVal: $($proc.ExitCode)" -f Red
        $cmdExitCode = $($proc.ExitCode)
        $cmdId =$($proc.Id)
        $cmdName=$($proc.Name)

        Write-Verbose "$process_ret.ExitCode $process_ret"
        $stdOut = Get-Content -Path $FNameOut -Raw
        $stdErr = Get-Content -Path $FNameErr -Raw
        if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
                $stdOut = $stdOut.Trim()
            }
        if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
                $stdErr = $stdErr.Trim()
            }
        $res = [PSCustomObject]@{
                Name            = $cmdName
                Id              = $cmdId
                ExitCode        = $cmdExitCode
                Output          = $stdOut
                Error           = $stdErr
                ElapsedSeconds  = $stopwatch.Elapsed.Seconds
                ElapsedMs       = $stopwatch.Elapsed.Milliseconds
          }
          Remove-Item -Path $FNameOut, $FNameErr -Force -ErrorAction Ignore

          return $res
        
    }
    catch {
        Show-ExceptionDetails($_) -ShowStack
    }
}
 


function Invoke-ShimGenProgram{     # NOEXPORT
    [CmdletBinding()]
    param (
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Name,
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Target
    )

    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}

    $ShimGenExePath=Get-ShimGenExePath
    # throw errors on undefined variables

    if(-not(Test-Path $ShimGenExePath)){
      Write-Error 'could not find shimgen.exe: $Executable'
        return
    }
    $ShimLocation=Get-ShimLocation
    $a1= '-o="' + $Name + '"'
    $a2= '-p="' + $Target + '"'
    $arguments = @()
    $arguments += $a1
    $arguments += $a2
    $file=(New-TemporaryFile).Fullname
    &"$ShimGenExePath" $arguments > $file

    return $?
}


function Get-ShimLocation{      # NOEXPORT
    [cmdletbinding()]
    Param()
    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}

    $ShimsPath=Get-RegistryValue (Get-ShimModuleRegistryPath) "shims_location" 
    if(Test-Path $ShimsPath -EA Ignore){
        Write-Verbose "Get-ShimLocation: check registry. returns $ShimsPath"
        if ($ShimsPath -notmatch '\\$'){
            $ShimsPath += '\'
        }
        return $ShimsPath
    }
    $ShimsPath=$Env:ShimsPath
    if(Test-Path $ShimsPath -EA Ignore){
        Write-Verbose "Get-ShimLocation: check Env:ShimsPath. returns $ShimsPath"
        if ($ShimsPath -notmatch '\\$'){
            $ShimsPath += '\'
        }
        return $ShimsPath
    }
    # current location
    $ShimsPath=(Get-Location -EA Ignore).Path
    if(Test-Path $ShimsPath){
        Write-ChannelResult "Get-ShimLocation: use current location. returns $ShimsPath" -Warning
       if ($ShimsPath -notmatch '\\$'){
            $ShimsPath += '\'
        }
        return $ShimsPath
    }

    return ""
}


function Get-IsShimInitialized{
    $res = Get-RegistryValue (Get-ShimModuleRegistryPath) "initialized" -ErrorAction Ignore
    if($res -eq $null){ return $false }
    if($res -ne 1){ return $false }
    return $true;
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
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. Files paths are not allowed."
            }
            return $true 
        })]
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path,
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a executable."
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

        $null=New-RegistryValue (Get-ShimModuleRegistryPath) "shimgen_exe_path" '$ShimGenPath' "string"

        if($AddToPath){
          Write-Output "Setup: add to system path"
          $Env:Path += ";$ShimLocation"
        }
        Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
        Write-Host "ShimGen Path set to $ShimGenPath"  
        Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
        Write-Host "Shims location set to $Path"  
        #[Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$Path",[EnvironmentVariableTarget]::User)
    }
    catch{
        Show-ExceptionDetails($_) -ShowStack
    }

}

function Invoke-AutoUpdateProgress{
	[int32]$PercentComplete = (($Script:StepNumber / $Script:TotalSteps) * 100)
	if($PercentComplete -gt 100){$PercentComplete = 100}
    Write-Progress -Activity $Script:ProgressTitle -Status $Script:ProgressMessage -PercentComplete $PercentComplete
    if($Script:StepNumber -lt $Script:TotalSteps){$Script:StepNumber++}
}


function Repair-AllShims{
<#
    .Synopsis
       Update all the shims on disk using the entries backed up in the registry
    .Description
       Update all the shims on disk using the entries backed up in the registry
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param ()
    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}
    $Script:StepNumber = 0
    $Script:TotalSteps = 1
    $Script:ProgressMessage = "REPAIRING ALL SHIMS..."
    $Script:ProgressTitle = "REPAIRING ALL SHIMS..."
    Invoke-AutoUpdateProgress  
	
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
    		Invoke-AutoUpdateProgress
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
	  $Files = (gci -Path (Get-ShimLocation) -File -Filter '*.exe').Fullname
	  foreach($f in $Files){
		Write-Host -ForegroundColor DarkRed "[Shim] " -NoNewline
		Write-Host "$f" -ForegroundColor DarkYellow
	  }
  }
}

function Remove-AllShims{
<#
    .Synopsis
       Update all the shims on disk using the entries backed up in the registry
    .Description
       Update all the shims on disk using the entries backed up in the registry
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param ()
    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}
    $Script:StepNumber = 0
    $Script:TotalSteps = 1
    $Script:ProgressMessage = "DELETNG ALL SHIMS..."
    $Script:ProgressTitle = "DELETNG ALL SHIMS..."
    Invoke-AutoUpdateProgress  
    write-host "WARNING" -f Red -b DarkGray -NoNewLine ; $a=Read-Host -Prompt "REMOVE ALL SHIMS. Are you sure (y/N)?" ; if($a -notmatch "y") {return;}
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
        Write-Verbose "Remove-AllShims: get entries in $RegBasePath* : $count"
        $Script:StepNumber = 0
        $Script:TotalSteps = $count

        foreach($Shim in $AllShimEntries){
            Invoke-AutoUpdateProgress
            $Script:ProgressMessage = "DELETE shim $Shim ($Script:StepNumber / $Script:TotalSteps)"
          
            $shimexists=Test-RegistryValue "$RegBasePath\$Shim" 'shim'
            if($shimexists){
                $Shim=(Get-ItemProperty "$RegBasePath\$Shim").Shim

                Remove-Item -Path $Shim -Force -ErrorAction Ignore | Out-null
            }
        }
        
    
        Remove-Item -Path $RegBasePath -Recurse -Force -ErrorAction Ignore | Out-null
    }catch{
      Show-ExceptionDetails($_) -ShowStack
    }
    finally{
      Write-Host -ForegroundColor DarkGreen "[DONE] " -NoNewline
      Write-Host " Remove-AllShims completed" -ForegroundColor DarkGray
      
  }
}
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

    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}
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

        if($Force){        
            $removed = Remove-Shim -Name $Name
        }
        Write-Verbose "Add-Shim: name is $Name"
        $ShimFullPath = $ShimLocation + $Name


        Write-ChannelMessage "Creating new shim"

        $exists1=Test-RegistryValue "$RegBasePath\$Name" 'target'
        $exists2=Test-RegistryValue "$RegBasePath\$Name" 'shim'
        if($exists1 -or $exists2){
            Write-ChannelResult -Warning -Message "shim already exists, delete before adding. Use -Force or See Remove-Shim"
            throw 'shim already exists, delete before adding. See "Remove-Shim"'
            return
        }
        Write-Verbose "New-Shim: $ShimFullPath"

        $Res = Test-Path $ShimFullPath
        if($Res -eq $true){
             Write-ChannelResult -Warning -Message "ALREADY EXISTS : $ShimFullPath"
             throw  "ALREADY EXISTS : $ShimFullPath"
             return $null
        }
        Write-ChannelMessage "$ShimFullPath ==> $Target"

        $Res = Invoke-ShimGenProgram $ShimFullPath $Target
        if($Res -eq $False){
             Write-ChannelResult -Warning -Message "FAILURE : Invoke-ShimGenProgram $ShimFullPath $Target"
             throw "FAILURE : Invoke-ShimGenProgram $ShimFullPath $Target"
             return $null
        }
        $Res = Test-Path $ShimFullPath
        if($Res -eq $False){
             Write-ChannelResult -Warning -Message "NOT FOUND : $ShimFullPath"
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
          Write-ChannelResult "Successfully created shim"
          Write-ChannelMessage "type '$Name' to run program."
          return $ShimFullPath
        }
    }
    catch{
        Show-ExceptionDetails($_) 
    }
}



