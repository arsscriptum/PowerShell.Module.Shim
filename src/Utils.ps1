<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Get-ShimModuleInformation{

        $ModuleName = $ExecutionContext.SessionState.Module
        $ModuleScriptPath = $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
        $ModuleScriptPath = (Get-Item "$ModuleScriptPath").DirectoryName
        $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
        $ModuleInformation = @{
            Module        = $ModuleName
            ModuleScriptPath  = $ModuleScriptPath
            CurrentScriptName = $CurrentScriptName
        }
        return $ModuleInformation
}

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
    $file="$ENV:Temp\out.log"
    &"$ShimGenExePath" $arguments > $file

    return $?
}


function Get-ShimLocation{     
    [cmdletbinding()]
    Param()
    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}

    $ShimsPath=Get-RegistryValue (Get-ShimModuleRegistryPath) "shims_location" 
    if(Test-Path $ShimsPath -EA Ignore -PathType Container){
        Write-Verbose "Get-ShimLocation: check registry. returns $ShimsPath"
        if ($ShimsPath -notmatch '\\$'){
            $ShimsPath += '\'
        }
        return $ShimsPath
    }
    $ShimsPath=$Env:ShimsPath
    if(Test-Path $ShimsPath -EA Ignore -PathType Container){
        Write-Verbose "Get-ShimLocation: check Env:ShimsPath. returns $ShimsPath"
        if ($ShimsPath -notmatch '\\$'){
            $ShimsPath += '\'
        }
        return $ShimsPath
    }
}



function Invoke-AutoUpdateProgress_Shim{
	[int32]$PercentComplete = (($Script:StepNumber / $Script:TotalSteps) * 100)
	if($PercentComplete -gt 100){$PercentComplete = 100}
    Write-Progress -Activity $Script:ProgressTitle -Status $Script:ProgressMessage -PercentComplete $PercentComplete
    if($Script:StepNumber -lt $Script:TotalSteps){$Script:StepNumber++}
}


function Invoke-ShimGenProgram{    
    [CmdletBinding(SupportsShouldProcess)]
    param (
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Name,
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Target
    )

    if ( -not (Get-IsShimInitialized) ) { throw 'not initialized'; return $false ;}
    Write-Verbose "Invoke-ShimGenProgram IsShimInitialized OK"
    $ShimGenExePath=Get-ShimGenExePath
    # throw errors on undefined variables
     Write-Verbose "Invoke-ShimGenProgram ShimGenExePath $ShimGenExePath OK"
    if(-not(Test-Path $ShimGenExePath)){
      Write-Error 'could not find shimgen.exe: $Executable'
        return $False
    }
    $ShimLocation=Get-ShimLocation
    $a1= '-o="' + $Name + '"'
    $a2= '-p="' + $Target + '"'
    $arguments = @()
    $arguments += $a1
    $arguments += $a2
    $file="$ENV:Temp\out.log"
    &"$ShimGenExePath" $arguments > $file
     Write-Verbose "$ShimGenExePath $arguments"
    return $?
}
