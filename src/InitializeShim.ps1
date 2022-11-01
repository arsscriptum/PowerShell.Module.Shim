<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Get-IsShimInitialized{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $res = Get-RegistryValue (Get-ShimModuleRegistryPath) "initialized" -ErrorAction Ignore
    if($res -eq $null){ return $false }
    if($res -ne 1){ return $false }
    return $true;
}



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