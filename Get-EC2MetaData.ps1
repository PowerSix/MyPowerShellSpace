<#
.SYNOPSIS
    Extract all instance metadata information.
.DESCRIPTION
    Get dynamic, meta and user data from the metadata server of the EC2 Windows or Linux instance.
.NOTES
    File name : Get-EC2MetaData.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-03-01
    Version   : 2018-03-01 - v1.1 - Now detecting types of userdata. Output reformatted. Colors added.
                2018-02-28 - v1.0 - Initial version.

    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/03/01/i-need-meta-data-all-of-it

    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.EXAMPLE
    Get-EC2MetaData.ps1
    Default run, no options or parameters available. Gets all the data and displays it on the screen.
.EXAMPLE
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/PowerSix/MyPowerShellSpace/master/Get-EC2MetaData.ps1")
    Handy way to run the script on a remote EC2 instance. As always, make sure to read the foreign code before executing it :)
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

$DynamicRoot = "http://169.254.169.254/latest/dynamic/instance-identity"
$MetaDataRoot = "http://169.254.169.254/latest/meta-data"
$UserDataRoot = "http://169.254.169.254/latest/user-data"

function Parse-MetaData($MetaData) {
    # Parse metadata URL and go deeper if it ends with /
    $Data = Invoke-RestMethod -Uri $MetaData
    foreach ($Line in $Data.Split([Environment]::NewLine)) {
        if ($Line.ToString().Substring($Line.Length-1) -eq "/") {
            Parse-MetaData("$MetaData/$($Line.Trim("/"))")
            $Result = $Line
        } else {
            try {
                $Result = Invoke-RestMethod -Uri $MetaData/$Line
            }
            catch {
                $Result = "ERROR"
            }
        }
    $Properties = [ordered]@{URL = "$MetaData/$Line"; Data = ($Result -split "`n").Trim()}
    New-Object -TypeName PSObject -Property $Properties
    }
}

Write-Host "`nDynamic data root: $DynamicRoot" -ForegroundColor Green
foreach ($Directory in "document", "signature", "pkcs7", "rsa2048") {
    Write-Host `n$Directory -ForegroundColor Yellow
    Invoke-RestMethod "$DynamicRoot/$Directory"
}

Write-Host "`n`n`nMetadata root: $MetaDataRoot`n" -ForegroundColor Green
Parse-MetaData($MetaDataRoot)

Write-Host "`nUserdata root: $UserDataRoot" -ForegroundColor Green
try {
    # Check if userdata exists
    Invoke-RestMethod $UserDataRoot | Out-Null
    # If XML object is returned, only PowerShell userdata is present
    if ((Invoke-RestMethod $UserDataRoot).powershell) {
        Write-Host "`nNo <script> tag found in userdata" -ForegroundColor Yellow
        Write-Host "`n<powershell>" -ForegroundColor Yellow
        (Invoke-RestMethod $UserDataRoot).powershell.Trim()
        Write-Host "</powershell>" -ForegroundColor Yellow
    # If both <script> and <powershell> tags are used a string is returned
    } else {
        $UserData = (Invoke-RestMethod $UserDataRoot)
        foreach ($Data in $UserData -split "`n") {
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
catch {
    Write-Host "`nNo userdata present" -ForegroundColor Yellow
}