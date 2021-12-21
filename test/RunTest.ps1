<#̷#̷\
#̷\ 
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#̷\ 
#̷##>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$false)]
    [switch]$Force
)  


function Show-ExceptionDetails{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Mandatory=$false)]
        [switch]$ShowStack
    )       
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    $Stack=$Record.ScriptStackTrace
    Write-Host "`n[ERROR] -> " -NoNewLine -ForegroundColor DarkRed; 
    Write-Host "$ExceptMsg`n`n" -ForegroundColor DarkYellow
    if($ShowStack){
        Write-Host "--stack begin--" -ForegroundColor DarkGreen
        Write-Host "$Stack" -ForegroundColor Gray  
        Write-Host "--stack end--`n" -ForegroundColor DarkGreen       
    }
}  



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


Write-Host "===============================================================================" -f DarkRed
Write-Host "TESTING MODULE   `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:ModuleIdentifier" -f Gray 
Write-Host "DATE             `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Date" -f Gray 
Write-Host "===============================================================================" -f DarkRed     

try{

    Remove-Item -Path $TmpPath -Recurse -Force -ErrorAction Ignore | Out-null
    New-Item -Path $TmpPath -ItemType Directory -Force -ErrorAction Ignore | Out-null

    #===============================================================================
    # Dependencies
    #===============================================================================
    $Script:BuildDependencies = @( Get-ChildItem -Path $Script:SourcePath -Filter '*.ps1' )
    $Script:DependencyCount = $Script:BuildDependencies.Count

    Write-Host "[Test] " -NoNewLine -f DarkYellow ;Write-Host "Importing module source to be tested from $Script:SourcePath ($Script:DependencyCount)..." -f DarkYellow;

    #Dot source the files
    Foreach ($file in $Script:BuildDependencies) {
        Try {
            $Depname = (Get-Item -Path $file).Name

            . "$file"
            Write-Host -f Green "[OK] " -NoNewline
            Write-Host " + $Depname imported" -f DarkGray
        }  
        Catch {
            Write-Error -Message "Failed to import file $file $_"
        }
    }




    Write-ChannelMessage  "Unloading module CodeCastor.PowerShell.Shim for test."
    remove-module 'CodeCastor.PowerShell.Shim' -ErrorAction Ignore

    $BackupFile = (New-TemporaryFile).Fullname
    $RootPath = "$ENV:OrganizationHKCU\shims'
    if(Test-Path $RootPath){
        Write-ChannelMessage  "SHIMS CONFIGURATION ALREADY PRESENT. BACKING UP...."
        # Define registry keys to export
        [array]$registryKey = @($RootPath)
        
        # Export keys and remove any binary data
        $Res = Invoke-Command  {reg export 'HKCU\SOFTWARE\CodeCastor\shims' "$BackupFile" /y}
        Write-ChannelMessage "Backup: '$BackupFile'"
        if($Res -match 'The operation completed successfully'){
             Write-ChannelResult "Backup Successfull"
        }
        else{
            Write-ChannelResult "Backup failure" -Warning
            if($Force -eq $False){ Write-ChannelResult "Quitting (use -Force to bypass)" -Warning ; return }
        }
    }
    Remove-Item -Path $RootPath -Recurse -Force -ErrorAction Ignore | Out-null
    New-Item -Path $RootPath -ItemType Directory -Force -ErrorAction Ignore | Out-null

    Sleep 1
    $TestShimPath = 'c:\Temp\Test\PowershellModule\Shim'
    Remove-Item -Path $TestShimPath -Recurse -Force -ErrorAction Ignore | Out-null
    New-Item -Path $TestShimPath -ItemType Directory -Force -ErrorAction Ignore | Out-null


    #Default value to this, but try to get the one in the path
    $ShimGenPath = $Script:shimgenPath
    $Cmd =  Get-Command 'shimgen.exe' -ErrorAction Ignore
    if($Cmd -ne $null){
       $ShimGenPath = $Cmd.Source
    }
    
    #===============================================================================
    # Script Variables
    #===============================================================================
    Write-ChannelMessage "###############################################"
    Write-ChannelMessage "TESTING Initialize-Shim"
    Write-ChannelMessage "###############################################"      
    Initialize-Shim -Path $TestShimPath -ShimGenPath $ShimGenPath
    Sleep 1

    $TestExe = Join-Path $TestShimPath 'test.exe'
    $Cmd = (Get-Command 'cmd.exe' -ErrorAction Ignore).Source
    #===============================================================================
    # Script Variables
    #===============================================================================
    Write-ChannelMessage "New-Shim -Target '$Cmd'"
    Write-ChannelMessage "###############################################"
    Write-ChannelMessage "TESTING New-Shim"
    Write-ChannelMessage "###############################################"    
    $Res = New-Shim -Target "$Cmd" -Name 'test'

    if(Test-Path $TestExe){
         Write-ChannelResult "New-Shim '$TestExe' SUCCESS"
    }else{
        throw "ERROR SHIM NOT CREATED"
    }
    
    #===============================================================================
    # Script Variables
    #===============================================================================
    Remove-Item $TestExe -Force -ErrorAction Ignore | Out-Null

    if(Test-Path $TestExe){
         throw "ERROR SHIM NOT DELETED"
    }
    Sleep 2
    Write-ChannelMessage "###############################################"
    Write-ChannelMessage "TESTING Repair-AllShims"
    Write-ChannelMessage "###############################################"
    Repair-AllShims

    if(Test-Path $TestExe){
         Write-ChannelResult "Repair-AllShim SUCCESS"
    }else{
        throw "ERROR SHIM NOT REPAIRED"
    }

    Sleep 2
}Catch {
    Write-Error -Message "Test Failure"
    Show-ExceptionDetails($_) -ShowStack
    return
}finally{
    Write-ChannelMessage "RESTORING BACKUP"
    $RootPath = "$ENV:OrganizationHKCU\shims'
    Remove-Item -Path $RootPath -Recurse -Force -ErrorAction Ignore | Out-null
    $Res = (Invoke-Command  {reg import $BackupFile })
    Repair-AllShims
}
