<#
.SYNOPSIS
    Get administrator password of your Windows EC2 instances.
.DESCRIPTION
    Run to get the instance information and password of your newest instances. Password unavailable for instances launched from AMIs.
.NOTES
    File name : Get-EC2Password.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2017-12-13
    Version   : 2018-04-17 - 1.6 - Fixed display of instances with no name tag.
                2018-03-27 - 1.5 - Added StateTransitionReason to output, for instances in Stopped and Terminated state.
                2018-03-21 - 1.4 - Proper parametrization added. Run -Help for information. -ShowTerminated switch will show otherwise suppressed output for terminated instances.
                2018-03-06 - 1.3 - Ignoring warning spam from updated Get-EC2PasswordData. Tag alias removed from Amazon.EC2.Model.Instance, using Tags now. Name duplication fixed.
                2017-12-12 - 1.2 - Added -Region switch and input parsing.
                2017-11-24 - 1.1 - Defaults to instances launched in last 24 hours. Specify [int]$DaysOld in days to override.
                2017-11-23 - 1.0 - Initial version.

    Script created as part of a learning tutorial at http://mypowershell.space
    http://mypowershell.space/index.php/2017/12/13/how-to-get-my-ec2-instance-password/

    Blog posts are NOT getting updated! Look for script updates on GitHub!
    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Expected functionality may be different, so make sure you give the script a test run first.
    Feel free to update/modify. I'd be interested in seeing it improved.

    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER KeyFolder
    Specifies the location of PEM keys. Defaults to C:\Users\<username>\Downloads\amazon\keys
.PARAMETER Region
    Specifies the region in which to look for EC2 instances. Defaults to eu-west-1.
.PARAMETER DaysOld
    Specifies the age of the instance to look for. Defaults to 1, covering instances launched in the last 24 hours.
.PARAMETER ShowTerminated
    If specified, terminated instances will be incuded in the output. Otherwise supressed.
.PARAMETER Help
    If specified, shows the script information.
.EXAMPLE
    Get-EC2Password.ps1
    Runs through all instances in the default region and provides information and password for ones not older than a day.
.EXAMPLE
    Get-EC2Password.ps1 -Region us-east-1 -DaysOld 10
    Runs through all instances in us-east-1 region and provides information and password for ones not older than 10 days.
.EXAMPLE
    Get-EC2Password.ps1 -KeyFolder C:\Keys
    Specifies the folder which holds EC2 instance private keys.
.EXAMPLE
    Get-EC2Password.ps1 -Help
    Displays detailed script information.
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [string]$KeyFolder = $(Join-Path -Path $env:USERPROFILE -ChildPath "Downloads\amazon\keys"),
    [string]$Region = "eu-west-1",
    [int]$DaysOld = 1,
    [switch]$ShowTerminated,
    [switch]$Help
)

# Display script information and exit
if ($Help) {
    Write-Host "`nFile name : " -ForegroundColor Cyan -NoNewLine
        Write-host "Get-EC2Password.ps1" -ForegroundColor Yellow
    Write-Host "Author    : " -ForegroundColor Cyan -NoNewLine
        Write-host "Sinisa Mikasinovic - six@mypowershell.space" -ForegroundColor Yellow
    Write-Host "Update    : " -ForegroundColor Cyan -NoNewLine
        Write-host "https://github.com/PowerSix/MyPowerShellSpace`n" -ForegroundColor Green

    Write-Host "Published : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-12-13" -ForegroundColor Yellow

    Write-Host "Version   : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-04-17 - 1.6 - Fixed display of instances with no name tag." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-03-27 - 1.5 - Added StateTransitionReason to output, for instances in Stopped and Terminated state." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-03-21 - 1.4 - Proper parametrization added. Run -Help for information. -ShowTerminated switch will show otherwise suppressed output for terminated instances." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-03-06 - 1.3 - Ignoring warning spam from updated Get-EC2PasswordData. Tag alias removed from Amazon.EC2.Model.Instance, using Tags now. Name duplication fixed." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-12-12 - 1.2 - Added -Region switch and input parsing." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-11-24 - 1.1 - Defaults to instances launched in last 24 hours. Specify [int]$DaysOld in days to override." -ForegroundColor Yellow
    Write-Host "          : " -ForegroundColor Cyan -NoNewLine
        Write-host "2017-11-23 - 1.0 - Initial version.`n" -ForegroundColor Yellow

    Write-Host "Examples  : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help Get-EC2Password.ps1 -Examples" -ForegroundColor Yellow
    Write-Host "Full help : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help Get-EC2Password.ps1 -Full`n" -ForegroundColor Yellow
    break
}

# Basic input parsing
if (!(Test-Path ($KeyFolder))) {
    Write-Host "`nERROR: Invalid key folder!" -ForegroundColor Yellow
    Write-Host "ERROR: $KeyFolder`n" -ForegroundColor Yellow
    break
}
if ($Region -notin (Get-AWSRegion).Region) {
    Write-Host "`nERROR: Invalid region! Run Get-AWSRegion for full list." -ForegroundColor Yellow
    Write-Host "ERROR: $Region`n" -ForegroundColor Yellow
    break
}

$TimeString = "yyyy-MM-dd HH:mm:ss"
$Instances = (Get-EC2Instance -Region $Region).Instances
$Results = @()
foreach ($Instance in $Instances) {
    # If there are multiple ENIs, get launch time from creation date (AttachTime) of primary ENI
    if ($Instance.NetworkInterfaces.Count -gt 2) {
        $NIC = $Instance.NetworkInterfaces.Attachment
        for ($i = 0; $i -lt $NIC.Count; $i++) {
            if ($NIC.DeviceIndex[$i] -eq 0) {$LaunchTime = $NIC.AttachTime[$i].ToString($TimeString)}
        }
    } elseif ($Instance.NetworkInterfaces.Count -eq 0) {
        $LaunchTime = "N/A :: Last start $($Instance.LaunchTime.Date.ToString($TimeString))"
    } else {
        $LaunchTime = $Instance.NetworkInterfaces.Attachment.AttachTime[0].ToString($TimeString)
    }

    if ($LaunchTime -gt (Get-Date).AddDays(-$DaysOld).ToString($TimeString)) {
        try {
            $Password = $(Get-EC2PasswordData -InstanceId $($Instance.InstanceId) -PemFile $($KeyFolder + "\" + $($Instance.KeyName) + ".pem") -Region $Region -WarningAction Ignore)
        }
        catch {
            if ($Instance.State.Name -eq "Terminated") {
                $Password = "* Terminated"
            } else {
                $Password = "* Not available"
            }
        }
        if (!$Password) {$Password = "* Not available"}

        $Name = ""
        foreach ($Tag in $Instance.Tags | Where-Object {$_.Key -eq "Name"}) {$Name = $($Tag.Value)}

        $Properties = [ordered]@{
            InstanceId = $Instance.InstanceId
            InstanceName = $Name
            Status = $Instance.State.Name
            PublicIp = $Instance.PublicIpAddress
            PrivateIp = $Instance.PrivateIpAddress
            Password = $Password
            LaunchTime = $LaunchTime
            TransitionReason = $Instance.StateTransitionReason
        }
        if ($Instance.State.Name -eq "Terminated" -and !($ShowTerminated)) {
            # Drop terminated instance output
        } else {
            $Result = New-Object -TypeName psobject -Property $Properties
            $Results = $Results + $Result
        }
    }
}
$Results | Format-Table
