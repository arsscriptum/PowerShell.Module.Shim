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

#Requires -Version 5
Set-StrictMode -Version 'Latest'

# ------------------------------------
# Script file - Assemblies - 
# ------------------------------------
$ScriptBlockAssemblies = "H4sIAAAAAAAACp1UbW/aMBD+jsR/ONFIBa2hn/alU6V2ULRJ0KKC1k1VP5jkKG6DnZ4doajrf985TngrVWEWirB9z708d4/rtWAUkUzt2Z1UsV6YS2NwPknyW5wioYrQwPlFs1Xfw+7LORwPCQ0qK6zUqkdijgtNz8f/g+5owr2B5e13YfbHjHJjcd4ujdo9TXNzKLhLYiHV44GwYzgwzO954jBy2gyG5heSYX7GYpJge7ltD8STJgjxBb62Xus14HVQjFGKGM24krd6bZqpyPUARjO9CN/jSv93JC2GP7Sx0OhL/ookgSgjNrJAqyhSwYcpNCCcQicXat+U/wJ36kpEs/Bm8oSRhTKZ7YQq6BksQ0B4ra9x0ZcKd2PgPhiOfjIbDwVmIB7dNHpbpoV/a9xcxvF7ajgZb54Knn7/t7kKdm8s8bw8BBXQX7UO6NcadDOfDqHgSj7sVjDSGUUI53DR8CeZ4VzA9/+bP1IsWZMKNhvkHa0s6cRflE5OTwE6R+BdLYlpXFRlB8xvN0mGws44UJN34RjnqSZBeU8m2Gq7K2/rCBznKULx7eJUKllUUmUa3mQ2zWxV0YbzcFlfXN5L5udTBrcj97n5JLzLzex5hVdEmi5LKXD2yiYFK1JlXLz3RWgzUuvQ7cbc4iOLAylcJbock6O+FjH7eMkkYQyJnDBTrpLtRKtSrrlBsPOVPYHt5/ME1t7FE9j14C1Py5esCOtj8z2yzKAZMH1Ow5+S21rX4pjy9e0n8uwKer5lAnYpdBvKKuWYXqIO9weTRC827T8gzgFXhm9VqW51hOVid2Z8J0g5pYQDNIbfBGj0BE9DDFaDdMNtC8elqgrPpTTcpxyH2j9IWfs7awcAAA=="


# ------------------------------------
# Script file - Helpers - 
# ------------------------------------
$ScriptBlockHelpers = "H4sIAAAAAAAACsVVXW/aMBR9j5T/YNFITSRA3WslHjYKbaXxsYSpm1AkvOQC1ozNbEcMIf777HxAAqGdtq5LHuz4Hl/fc+/xjW3Z+o0olhJ1l5gxoGPB1yAUAWlbO9tC+rmqMZn1qVSCsEXo5HbUQdfBw+PgOjd3OZOcQpdTLkJnQlQ+N7ivQCnf1CMHICVeHLF3WHy/F3hbj+4JwUUF60NcDw2SKNK+TxwDsGc834GMBFkrwlll34HA3race8q/YXpbypPUuOlZ3sLbWwYb1zNZt615wiLjFz0JoqCVo3P2OxNQ6blCw1Hvy3jkT/RHEe4qpqA+EBbrMrhBsl5zoWSw5AmN9aGGqxdm2DUWeOVm83Tv2CyAAuEOMIux4mLbcZRIoDnmkpiwOjfF5kqx8/iK9QyRMjKTjMoDlwo1po5bl5l2/uGFqIFac3QBddSLh1pDPoTNR8Lg/JQioOd8lRXlpSW7nH8fZELVafrr61DKwH8tRrNs2hAVLUPnCQumMSf1IXO3sKAW/EBOH1MJXn7TX7eC5et2XsPTs1DwudvtBcFfuNyD5vJPqBybzG8Q6fn+yH/Z3WlnqeGTDa+p+UuqTyPavSx29Baqr0g92EoFq7aGaDYrYKr9PlF8hQ2HLJE+RFzEoZONB8GbwZlzoaHZddEtubG72c/Y7t2+UdgJ0Ng063x3u59Quv2UYEq0KU79P8bNwtr7GUFasfaEB6lT08xTT5lpIBcdt3pqS5coOyaHvn2PnKaS/HOJV7R3IDpjM6Y99rmAheAJi7Mf5PHvmKrO+gVJDew0ZQgAAA=="

# ------------------------------------
# Script file - MessageBox - 
# ------------------------------------
$ScriptBlockMessageBox = "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"

# ------------------------------------
# Script file - Registry - 
# ------------------------------------
$ScriptBlockRegistry = "H4sIAAAAAAAACu1UTU+DQBC9k/Af9sABEvkJPXioxoO0aRsvpgfEocXALhkGlaj/3V2WkoVSWy0Xo8uBXZivN2/e2lZc8ogSwdkKCvIXsEkKwuouTEuwrTfbYnLlIYYZc/WB3ddHIED3NuSPIQmsJg5hCd56ZyL9E/kHAkFBmaYznGY5Va63duYhbS9GiTTlslBt5tmW3iSx63NBbg1GpWJ1Qs9rkKiFQCVy5sRhWkiM6tOHfsl4zDC8BvJvCLI5ihyQKmZEZO9sCSlE5M8enuSL+dPXXGJobXV58jOiwEvd4iWJXDrOSvIVlv2SFPS2Ir2JQoq27Gj5tb16Wj5V9f90Go1zFlCUKU3cEXj19vnQ0U9lj7f869kzGDQ4XP4yDgPpOk6kBm1H3CepO4CXmtwOqf6VwAhYV43JhguERo8dPgZvA5l8/4rsZtGSr7tglqTWAjLxDIfHzldO2vVb1Rq3lxqifheO59IwdL93mYeSnH9F1Ro0IM0RYkDgMuGk82NYCwrSH9bCOKFWVd5X1YEx15NiiKw30OfJ4YeSOFURHVV0tiAnslfLVzfGAbmdL7SdvSKE1bSwwWQjC7CRlvUJylTa/vgJAAA="


# ------------------------------------
# Script file - Miscellaneous - 
# ------------------------------------
$ScriptBlockMiscellaneous = "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"


# ------------------------------------
# Script file - Date - 
# ------------------------------------
$ScriptBlockDate = "H4sIAAAAAAAACsVUXWvbMBR9D+Q/iGKwDFFIYWxroA9blo4yUsKc9sUxRbVvEoEtGUleFkr++yRbynf72Ak/SNdX555z7rW7nW5nUfNMM8HRT9DkB9UQa8n4EidqzXS2SoMnkC9CQfTaNdnILLbAh0EbskuCriVHGHugqG92djNjJdwJWVKtcJR8TaP+b6gKmgEOUdgLn8OoPxOubNQCbn2xIKtlbjDQLQrw0iA3B9LCoauNWWQyIXn+PF+tVmRemkXmSqkrh+Ro7XC6ne1F2S2i0+O1vC/FQR2AjQT/A1LfSVGSkTa5CCf3XH/+lAYmoYQIuQKJ5WIjaQCVyFZGXnh982VABtfmQYPBsHlCm3t2Q4KqC20dae72v+V5DJngucJBU/VEepv/JtuZIKNZy3Vf455XtR5b+Eucx+9xdtms1d3acIsGu476CH6ANbGF44pyRGJNpUYOmox5jg5JmAnRtHAyj+U1eKdtPezEI2d/bR2vY1TmBejvjOfNxKVtuKKSlng/z8nUBkCDxBPKjXYhNz30RIsaLOqUVVAwDj00FYo1NY1ID9YAuM778u0b15sXWDLunW1s8XOQ+DlLh8O4gowtNr8MVXzgddhD4aPOwv3H0giQIgOlzkGPBsSz2d/dvjEUPhN9tG87AwK/+w/WJW338I6DmUDjiPFG0cKecYSIK31pOs+Mtf+SU0uDB7E2vP1v5miuLzTCpjvYzj/QxPw4vAUAAA=="


# ------------------------------------
# Script file - Shims - 
# ------------------------------------
$ScriptBlockShims = "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"



function DoMsgBox{
[CmdletBinding(SupportsShouldProcess)]
param (

    [parameter(Position=0,Mandatory=$true)]
    [string]$Message
)  
        $Params = @{
            Content = "$Message"
            Title = "STATUS"
            ContentBackground = "WhiteSmoke"
            FontFamily = "Consolas"
            TitleFontWeight = "DemiBold"
            TitleBackground = "Gray"
            TitleTextForeground = "Blue"
        
            ButtonType = 'Ok'
   
 
        }
         
        Show-MessageBox @Params
}

# ------------------------------------
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        $ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

    # Then decompress script's data
    $InputStream = New-Object System.IO.MemoryStream(, $ScriptBlockCompressed)
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $StreamReader = New-Object System.IO.StreamReader($GzipStream)
    $ScriptBlockDecompressed = $StreamReader.ReadToEnd()
    # And close the streams
    $GzipStream.Close()
    $InputStream.Close()

    $ScriptBlockDecompressed
}


# For each scripts in the module, decompress and load it.

$ScriptList = @('Helpers', 'MessageBox', 'Registry', 'Miscellaneous', 'Date', 'Shims')
$ScriptList | ForEach-Object {
    $ScriptBlock = "`$ScriptBlock$($_)" | Invoke-Expression
    ConvertFrom-Base64CompressedScriptBlock -ScriptBlock $ScriptBlock | Invoke-Expression
}

$IcoPath = [Environment]::GetFolderPath("MyPictures")
$IcoPath = Join-Path $IcoPath 'MyShim.png'


$RootPath = "$ENV:OrganizationHKCU\shims"
if(-not(Test-Path $RootPath)){
    Write-ChannelMessage  "Missing Shim configuration"
}

$RegBasePath = "$ENV:OrganizationHKCU\shims"
$check1=Test-RegistryValue "$RegBasePath" "shimgen_exe_path"
$check2=Test-RegistryValue "$RegBasePath" "shims_location"
if($check1 -and $check2){
    $shimgen=Get-RegistryValue "$ENV:OrganizationHKCU\shims" "shimgen_exe_path" 
    $shims=Get-RegistryValue "$ENV:OrganizationHKCU\shims" "shims_location" 
}else{
     Write-ChannelMessage   "Shim Configuration not completed`nref Initialize-Shim" -Warning
    #PopupError "Shim Configuration not completed`nref Initialize-Shim"
    return 
}

$res = New-Shim -Target $TargetPath  
if($res){
    DoMsgBox "New Shim"
}
sleep 1


