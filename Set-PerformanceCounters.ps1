<#
.SYNOPSIS
    Automate creation of Performance Monitor Data Collector on an EC2 instance or a WorkSpace
.DESCRIPTION
    Script takes an XML file with defined settings and automates the creation of a a data collector. Helps with the troubleshooting of inaccessible / secure systems.
.NOTES
    File name : Set-PerformanceCounters.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-05-10
    Version   : 2017-10-12 - v1.1 - Improved error capture and handling.
                2017-10-11 - v1.0 - Initial version.
    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/05/10/automate-creation-of-performance-monitor-data-collector-on-an-ec2-instance-or-a-workspace
    Blog posts are NOT getting updated! Look for script updates on GitHub!
    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace
    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.
    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER Help
    Displays script information and usage.
.EXAMPLE
    Set-PerformanceCounters.ps1
    Runs with no specified parameters. Default script run.
.EXAMPLE
    Invoke-Expression (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/PowerSix/MyPowerShellSpace/master/Set-PerformanceCounters.ps1")
    Invoke the latest version remotely. Be sure to check the script beforehand to know what you're executing :-)
.EXAMPLE
    Set-PerformanceCounters.ps1 -Help
    Displays detailed script information.
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [switch]$Help
)

# Display script information and exit
if ($Help) {
    Write-Host "`nFile name : " -ForegroundColor Cyan -NoNewLine
        Write-host "Set-PerformanceCounters.ps1" -ForegroundColor Yellow
    Write-Host "Author    : " -ForegroundColor Cyan -NoNewLine
        Write-host "Sinisa Mikasinovic - sinisam@gmail.com" -ForegroundColor Yellow
    Write-Host "Update    : " -ForegroundColor Cyan -NoNewLine
        Write-host "https://github.com/PowerSix/MyPowerShellSpace`n" -ForegroundColor Green

    Write-Host "Published : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-05-10" -ForegroundColor Yellow

    Write-Host "Version   : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-10-12 - 1.1 - Improved error capture and handling." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-10-11 - 1.0 - Initial version." -ForegroundColor Yellow

    Write-Host "Examples  : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help Set-PerformanceCounters -Examples" -ForegroundColor Yellow
    Write-Host "Full help : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help Set-PerformanceCounters -Full`n" -ForegroundColor Yellow
    break
}

# Download Data Collector XML template
try {
    (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/PowerSix/MyPowerShellSpace/master/Set-PerformanceCounters.xml", "$env:TEMP\PerformanceCounters.xml")
}
catch {
    Write-Output "`n[ERROR] Download failed. Are you running PowerShell as Administrator?"
    Write-Output $Error[0].Exception.Message
    Write-Output "`n`n`n[ERROR] Full error output for analysis:"
    Write-Output $Error[0] | Format-List * -Force
    break
}

# Create the Data Collector
try {
    $DataCollectorSet = New-Object -COM Pla.DataCollectorSet
    $XML = Get-Content "$env:TEMP\PerformanceCounters.xml"
    $DataCollectorSet.SetXml($xml)
    $DataCollectorSet.Commit("CustomPerformance", $null, 0x0003) | Out-Null
    $DataCollectorSet.Start($true)
    Write-Output "[SUCCESS] Data Collector 'CustomPerformance' successfully created."
}
catch [System.UnauthorizedAccessException] {
    Write-Output "`n[ERROR] Insufficient permissions to create Data Collector! Are you running PowerShell as Administrator?"
    Write-Output $Error[0].Exception.Message
    Write-Output "`n`n`n[ERROR] Full error output for analysis:"
    Write-Output $Error[0] | Format-List * -Force
}
catch [System.Runtime.InteropServices.COMException] {
    Write-Output "`n[ERROR] Duplication detected! Task already exists. Remove it and all files first, and retry."
    Write-Output $Error[0].Exception.Message
    Write-Output "`n`n`n[ERROR] Full error output for analysis:"
    Write-Output $Error[0] | Format-List * -Force
}
catch {
    Write-Output "`n[ERROR] Error creating Data Collector!"
    Write-Output $Error[0].Exception.Message
    Write-Output "`n`n`n[ERROR] Full error output for analysis:"
    Write-Output $Error[0] | Format-List * -Force
}
