<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


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
    Invoke-AutoUpdateProgress_Shim  
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
            Invoke-AutoUpdateProgress_Shim
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

