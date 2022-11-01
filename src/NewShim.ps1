<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


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



