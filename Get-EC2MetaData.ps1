<#
.SYNOPSIS
    Extract all instance metadata information.
.DESCRIPTION
    Get dynamic, user and meta data from the metadata server of the EC2 Windows or Linux instance.
.NOTES
    File name : Get-EC2MetaData.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-03-01
    Version   : 2018-03-08 - v2.0 - Avoiding proxy. Reformated output, basic format avaiable. Able to specify separated data root folders and log locations. Quiet and log run modes added.
                2018-03-01 - v1.1 - Now detecting types of userdata. Output reformatted. Colors added.
                2018-02-28 - v1.0 - Initial version.

    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/03/01/i-need-meta-data-all-of-it

    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER Root
    Specifies the scope of script. Allowed values "DynamicData", "UserData", "MetaData" and "All". Defaults to All.
.PARAMETER RootDynamicData
    Specifies the root URL for dynamic data. Defaults to "http://169.254.169.254/latest/dynamic/instance-identity".
.PARAMETER RootUserData
    Specifies the root URL for user data. Defaults to "http://169.254.169.254/latest/user-data".
.PARAMETER RootMetaData
    Specifies the root URL for meta data. Defaults to "http://169.254.169.254/latest/meta-data".
.PARAMETER Log
    If specified, log files will be created. Required for LogDynamicData, LogUserData and LogMetaData.
.PARAMETER LogDynamicData
    Specifies the location of dynamic data log file. Defaults to "$env:USERPROFILE\Desktop\Get-EC2MetaData_DynamicData.csv".
.PARAMETER LogUserData
    Specifies the location of dynamic data log file. Defaults to "$env:USERPROFILE\Desktop\Get-EC2MetaData_UserData.txt".
.PARAMETER LogMetaData
    Specifies the location of dynamic data log file. Defaults to "$env:USERPROFILE\Desktop\Get-EC2MetaData_MetaData.csv".
.PARAMETER Basic
    Uses raw data for output. Supresses colors.
.PARAMETER Quiet
    Supresses output. Useful only with -Log parameter.
.EXAMPLE
    .\Get-EC2MetaData.ps1
    Default run. Gets all the data and displays it colored on the screen.
.EXAMPLE
    .\Get-EC2MetaData.ps1 -Root UserData -Basic
    Runs only against user data root. Displays raw information.
.EXAMPLE
    .\Get-EC2MetaData.ps1 -Root MetaData -Log -LogMetaData $env:USERPROFILE\Desktop\MetaData.log
    Runs only against meta data root. Displays colored information and creates log on desktop.
.EXAMPLE
    .\Get-EC2MetaData.ps1 -Root All -Quiet -Log
    Runs against all data roots. Doesn't display output and creates default logs for each root.
.EXAMPLE
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/PowerSix/MyPowerShellSpace/master/Get-EC2MetaData.ps1")
    Handy way to run the script on a remote EC2 instance. As always, make sure to read the foreign code before executing it :)
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [ValidateSet("DynamicData", "UserData", "MetaData", "All")]
    [string]$Root = "All",
    [string]$RootDynamicData = "http://169.254.169.254/latest/dynamic/instance-identity",
    [string]$RootUserData = "http://169.254.169.254/latest/user-data",
    [string]$RootMetaData = "http://169.254.169.254/latest/meta-data",
    [switch]$Log,
    [string]$LogDynamicData = "$env:USERPROFILE\Desktop\Get-EC2MetaData_DynamicData.csv",
    [string]$LogUserData = "$env:USERPROFILE\Desktop\Get-EC2MetaData_UserData.txt",
    [string]$LogMetaData = "$env:USERPROFILE\Desktop\Get-EC2MetaData_MetaData.csv",
    [switch]$Basic,
    [switch]$Quiet
)

# Create a web client to avoid a possible proxy server
$WebClient = New-Object System.Net.WebClient
$WebClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()

# Finder function for dynamic data
function Find-DynamicData {
    foreach ($Directory in "document", "signature", "pkcs7", "rsa2048") {
        New-Variable -Name "Dynamic$Directory" -Value $WebClient.DownloadString("$RootDynamicData/$Directory")
    }
    return $DynamicDocument, $DynamicSignature, $DynamicPkcs7, $DynamicRsa2048
}

# Finder function for user data
function Find-UserData {
    try {
        $UserData = $WebClient.DownloadString($RootUserData)
    }
    catch {
        $UserData = "No userdata present"
    }
    return $UserData
}

# Finder function for meta data
function Find-MetaData {
    function Search-MetaData($MetaData) {
        $Data = $WebClient.DownloadString($MetaData)
        foreach ($Line in $Data.Split([Environment]::NewLine)) {
            if ($Line.ToString().Substring($Line.Length-1) -eq "/") {
                Search-MetaData("$MetaData/$($Line.Trim("/"))")
                $Result = $Line
            } else {
                try {
                    $Result = $WebClient.DownloadString("$MetaData/$Line")
                }
                catch {
                    $Result = "ERROR"
                }
            }
            if (!($Result.Substring($Result.Length-1) -eq "/")) {
                $Properties = [ordered]@{URL = "$MetaData/$Line"; Data = ($Result -split "`n").Trim()}
                New-Object -TypeName PSObject -Property $Properties
            }
        }
    }
    Search-MetaData($RootMetaData)
}

# Check if dynamic data was requested
if ($Root -in "DynamicData", "All") {
    $DynamicDocument, $DynamicSignature, $DynamicPkcs7, $DynamicRsa2048 = Find-DynamicData

    $Properties = [ordered]@{
        Document = $DynamicDocument
        Signature = $DynamicSignature
        PKCS7 = $DynamicPkcs7
        RSA2048 = $DynamicRsa2048
    }
    $Result = New-Object -TypeName PSObject -Property $Properties

    if (!$Quiet) {
        # Display output
        if ($Basic) {
            # Display in basic mode
            Write-Output $Result | Format-List
        } else {
            # Display in colorful mode
            Write-Host "`nDynamic data root: $RootDynamicData" -ForegroundColor Green
            foreach ($Directory in "Document", "Signature", "PKCS7", "RSA2048") {
                Write-Host "`n$Directory" -ForegroundColor Yellow
                (Get-Variable -Name "Dynamic$Directory").Value
            }
        }
    }

    if ($Log) {
        # Save a log file
        if (!$Quiet) {
            Write-Host "`nSaved to $LogDynamicData`n`n" -ForegroundColor Yellow
        } else {
            Write-Host "`n`n"
        }
        $Result | Export-Csv -Path $LogDynamicData
    }
}

# Check if user data was requested
if ($Root -in "UserData", "All") {
    $FoundUserData = Find-UserData
    if (!$Quiet) {
        # Display output
        if ($Basic) {
            # Display in basic mode
            Write-Output $FoundUserData
        } else {
            # Display in colorful mode
            Write-Host "`nUser data root: $RootUserData" -ForegroundColor Green
            foreach ($Data in $FoundUserData -split "`n") {
                if ($Data -eq "<script>" -or $Data -eq "<powershell>") {
                    Write-Host "`n$Data" -ForegroundColor Yellow
                } elseif ($Data -eq "</script>" -or $Data -eq "</powershell>") {
                    Write-Host "$Data" -ForegroundColor Yellow
                } else {
                    Write-Host "$Data"
                }
            }
        }
    }

    if ($Log) {
        # Save a log file
        if (!$Quiet) {
            Write-Host "`nSaved to $LogUserData`n`n" -ForegroundColor Yellow
        } else {
            Write-Host "`n`n"
        }
        Out-File -InputObject $FoundUserData -FilePath $LogUserData
    }
}

# Check if meta data was requested
if ($Root -in "MetaData", "All") {
    $FoundMetaData = Find-MetaData
    if (!$Quiet) {
        # Display output
        if ($Basic) {
            # Display in basic mode
            Write-Output $FoundMetaData | Format-List
        } else {
            # Display in colorful mode
            Write-Host "`nMeta data root: $RootMetaData" -ForegroundColor Green
            Write-Output $FoundMetaData
        }
    }

    if ($Log) {
        # Save a log file
        if (!$Quiet) {
            Write-Host "`nSaved to $LogMetaData`n`n" -ForegroundColor Yellow
        } else {
            Write-Host "`n`n"
        }
        $FoundMetaData | Export-Csv -Path $LogMetaData
   }
}
