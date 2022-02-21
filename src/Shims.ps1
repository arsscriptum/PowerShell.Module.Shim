<#̷#̷\
#̷\ 
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#̷\ 
#̷##>



function Get-ShimGenExePath{
    [cmdletbinding()]
    Param()
    $Exists=Test-RegistryValue "$ENV:OrganizationHKCU\shims" "shimgen_exe_path"
    if($Exists){
        $ShimGenExe=Get-RegistryValue "$ENV:OrganizationHKCU\shims" "shimgen_exe_path"
        if(Test-Path $ShimGenExe){
          return $ShimGenExe  
        }    
    }
    
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
    $ShimsPath=Get-RegistryValue "$ENV:OrganizationHKCU\shims" "shims_location" 
    if(Test-Path $ShimsPath){
        Write-Verbose "Get-ShimLocation: check registry. returns $ShimsPath"
        return $ShimsPath
    }
    $ShimsPath=$Env:ShimsPath
    if(Test-Path $ShimsPath){
        Write-Verbose "Get-ShimLocation: check Env:ShimsPath. returns $ShimsPath"
        return $ShimsPath
    }
    # current location
    $ShimsPath=(Get-Location).Path
    if(Test-Path $ShimsPath){
        Write-Verbose "Get-ShimLocation: use current location. returns $ShimsPath"
        return $ShimsPath
    }

    return ""
}



function Initialize-Shim{
<#
    .Synopsis
       Setup the shim system. Needs to be run only once
    .Description
       Setup the shim system by creating the registry keys, add a PATH entry

    .Parameter Path
       Path where we store all the shims 

    .Example
       Initialize-Shim -Path 'c:\Programs\Shims'
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

    try {
        Write-Output "Setup: add to registry"
        Write-Verbose "Setup: new registry HKCU:\Software\CodeCastor\shims - shims_location $Path"
        $null=New-RegistryValue "$ENV:OrganizationHKCU\shims" "shims_location" $Path "string"
        $ShimGenPath = Get-ShimGenExePath 
        Write-Verbose "Setup: new registry HKCU:\Software\CodeCastor\shims - shimgen_exe_path $ShimGenPath"
        $null=New-RegistryValue "$ENV:OrganizationHKCU\shims" "shimgen_exe_path" $ShimGenPath "string"

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


function Repair-AllShims{
<#
    .Synopsis
       Update all the shims on disk using the entries backed up in the registry
    .Description
       Update all the shims on disk using the entries backed up in the registry
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param ()

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
    $RegBasePath = "$ENV:OrganizationHKCU\shims\"
 
    
    $AllShimEntries=(Get-Item "$RegBasePath\*").PSChildName
    $count=$AllShimEntries.Count
    Write-Verbose "Repair-AllShims: get entries in $RegBasePath* : $count"
   
    foreach($Shim in $AllShimEntries){
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
  }
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
     [ValidateNotNullOrEmpty()]$Name
    )

    $ShimGenExe=Get-ShimGenExePath
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

        Write-ChannelMessage "Creating new shim"

        $exists1=Test-RegistryValue "$ENV:OrganizationHKCU\shims\$Name" 'target'
        $exists2=Test-RegistryValue "$ENV:OrganizationHKCU\shims\$Name" 'shim'
        if($exists1 -or $exists2){
            throw 'shim already exists, delete before adding. See "Remove-Shim"'
            return
        }

        Write-Verbose "Add-Shim: name is $Name"
        $ShimFullPath = $ShimLocation + $Name

        if ($Name.get_Length() -gt 4)
        {
            $lastchars=$Name.Substring($Name.get_Length()-4)
            if($lastchars -notmatch ".exe")
            {
                Write-Verbose "New-Shim: adding suffix $Sfix.  $ShimFullPath"
                Write-ChannelMessage "New-Shim: adding suffix $Sfix to name."
                $ShimFullPath += '.exe'
            }
        }
        else{
            $ShimFullPath += '.exe'
        }

        Write-ChannelMessage "$ShimFullPath ==> $Target"

        Invoke-ShimGenProgram $ShimFullPath $Target
        $Res = Test-Path $ShimFullPath

        Write-ChannelMessage " Presence of new shim: $Res"
        if($Res -eq $True){
          $null=New-RegistryValue "$ENV:OrganizationHKCU\shims\$Name" 'target' $Target "string"
          $null=New-RegistryValue "$ENV:OrganizationHKCU\shims\$Name" 'shim'   $ShimFullPath "string"
          Write-ChannelResult "Successfully created shim"
          Write-ChannelMessage "type '$Name' to run program."
          return $true
        }
        return $False
    }
    catch {
        return $False
    }
}



