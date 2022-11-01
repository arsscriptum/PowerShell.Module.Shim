<#̷#̷\
#̷\ 
#̷\
#̷\   Generated on Tue, 07 Dec 2021 15:21:31 GMT 
#̷\
#̷##>

[CmdletBinding(SupportsShouldProcess)]
param (

    [parameter(Position=0,Mandatory=$true)]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "File or folder does not exist"
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The Path argument must be an executable."
        }
        return $true 
    })]
    [string]$TargetPath,
    [parameter(Position=1,Mandatory=$false)]
    [string]$Name
)  


import-module "C:\DOCUMENTS\PowerShell\Modules\PowerShell.Module.Shim\PowerShell.Module.Shim.psd1" -Verbose
 $PSVersionTable
Start-Sleep 4
$TargetName=(Get-Item "$TargetPath" -ErrorAction Ignore).Name
Write-Output "New-Shim -Target `"$TargetPath`" -Name `"$TargetName`" -Force"
Start-Sleep 4
$res = New-Shim -Target "$TargetPath" -Name "$TargetName" -Force
Write-Output "res is $res" 
Start-Sleep 4
$app=Get-Item $res -ErrorAction Ignore
if($app){
    $path = $app.DirectoryName
    $ExpExe = (Get-Command "explorer.exe").Source
    &"$ExpExe" "$path"
}

Start-Sleep 4