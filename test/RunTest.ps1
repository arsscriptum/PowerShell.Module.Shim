<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param()




#===============================================================================
# Script Variables
#===============================================================================
$Script:RootPath                       = (Resolve-Path "$PSScriptRoot\..").Path
$Script:Time                           = Get-Date
$Script:Date                           = $Time.GetDateTimeFormats()[19]
$Script:SourcePath                     = Join-Path $Script:RootPath "src"
$Script:BinPath                        = Join-Path $Script:RootPath "bin"
$Script:TmpPath                        = Join-Path $ENV:Temp "ShimTest"
$Script:shimgenPath                    = Join-Path $Script:BinPath "shimgen.exe"
$Script:ModuleIdentifier               = 'Shim'
$Script:ShimModuleRegistryPath         = Get-ShimModuleRegistryPath
$Script:ShimModuleInformation          = Get-ShimModuleInformation
$Script:ModuleScriptPath               = $Script:ShimModuleInformation.ModuleScriptPath
$Script:DummyTestExe                   = Join-Path $Script:ModuleScriptPath "bin\dummytest.exe"
Write-Host "===============================================================================" -f DarkRed
Write-Host "TESTING MODULE         `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:ModuleIdentifier" -f Gray 
Write-Host "DATE                   `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Date" -f Gray 
Write-Host "ShimModuleRegistryPath `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:ShimModuleRegistryPath" -f Gray 
Write-Host "===============================================================================" -f DarkRed     

try{

    Write-Log "Test Shim Module => Deleting $Script:ShimModuleRegistryPath"
    Remove-Item -Path $Script:ShimModuleRegistryPath -Recurse -Force -ErrorAction Ignore | Out-null
    $IsShimInitialized = Get-IsShimInitialized
    #===============================================================================
    # TESTING New-Shim
    #===============================================================================
    Write-Log "###############################################"
    Write-Log "TESTING Initialize-Shim"
    Write-Log "###############################################"      
    Sleep 1

    Write-Host "IsShimInitialized `t" -NoNewLine -f DarkYellow;  Write-Host "$IsShimInitialized" -f Gray 
    Write-Host "INITIALIZING MODULE         `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:ModuleIdentifier" -f Gray 
    Initialize-ShimModuleWithDefault
    $IsShimInitialized = Get-IsShimInitialized
    Write-Host "IsShimInitialized `t" -NoNewLine -f DarkYellow;  Write-Host "$IsShimInitialized" -f Gray 
    #===============================================================================
    # TESTING New-Shim
    #===============================================================================
    Write-Log "###############################################"
    Write-Log "TESTING New-Shim"
    Write-Log "###############################################"     
    Sleep 1
    $TestExe = "dummytest.exe"
    Write-Log "New-Shim -Target `"$Script:DummyTestExe`" -Name `"$TestExe`""
    $CreatedShim = New-Shim -Target "$Script:DummyTestExe" -Name "$TestExe" -Force
    if(Test-Path $CreatedShim){
         Write-Log "New-Shim '$CreatedShim' SUCCESS"
    }else{
        throw "ERROR SHIM NOT CREATED"
    }

   Remove-Item $CreatedShim -Force -ErrorAction Ignore | Out-Null

    if(Test-Path $CreatedShim){
         throw "ERROR SHIM NOT DELETED"
    }
    Sleep 2
    Write-Log "###############################################"
    Write-Log "TESTING Repair-AllShims"
    Write-Log "###############################################"
    Repair-AllShims

    if(Test-Path $CreatedShim){
         Write-Log "Repair-AllShim SUCCESS"
    }else{
        throw "ERROR SHIM NOT REPAIRED"
    }

    #===============================================================================
    # TESTING New-Shim
    #===============================================================================
    Write-Log "###############################################"
    Write-Log "TESTING Remove-Shim"
    Write-Log "###############################################"     
    Sleep 1
    $Res = Remove-Shim $TestExe
    if($Res){
         Write-Log "Remove-Shim '$TestExe' SUCCESS"
    }else{
        throw "ERROR SHIM NOT REMOVED"
    }


}Catch {
    Write-Error -Message "Test Failure"
    Show-ExceptionDetails($_) -ShowStack
    return
}