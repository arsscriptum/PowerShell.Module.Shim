

[CmdletBinding(SupportsShouldProcess)]
param (

    [parameter(Position=0,Mandatory=$true)]
    [string]$Path
)  

$Name = (gi -Path $Path).Name

Remove-Shim $Name
