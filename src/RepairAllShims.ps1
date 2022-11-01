<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



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