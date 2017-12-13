<# 
.SYNOPSIS 
	Get administrator password of your Windows EC2 instances.
.DESCRIPTION 
    Run to get the instance information and password of your newest instances. Password unavailable for instances launched from AMIs.
.NOTES 
    File name : Get-EC2Password.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 13-Dec-17
	Version   : 2017-12-12 - 1.2 - Added -Region switch and input parsing.
	Version   : 2017-11-24 - 1.1 - Defaults to instances launched in last 24 hours. Specify [int]$DaysOld in days to override.
	Version   : 2017-11-23 - 1.0 - Initial version.

	Script created as part of a learning tutorial at http://mypowershell.space
	http://mypowershell.space/index.php/2017/12/13/how-to-get-my-ec2-instance-password/
	
	More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Expected functionality may be different, so make sure you give the script a test run first.
    Feel free to update/modify. I'd be interested in seeing it improved.

	This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.EXAMPLE 
    Get-EC2Password.ps1
	Runs through all instances in the default region and provides information and password for ones not older than a day.
.EXAMPLE 
    Get-EC2Password.ps1 10
	Runs through all instances in the default region and provides information and password for ones not older than 10 days.
.EXAMPLE 
    Get-EC2Password.ps1 40 us-east-1
	Runs through all instances in us-east-1 region and provides information and password for ones not older than 40 days.
.EXAMPLE 
    Get-EC2Password.ps1 us-east-1
	This will get you nowhere :-) Modify script default parameters to change the functionality.
.LINK 
	http://mypowershell.space
.LINK
	https://github.com/PowerSix/MyPowerShellSpace
#>

# Default settings
# KeyFolder must be valid
$KeyFolder = "C:\Users\$env:USERNAME\Ec2Keys"
$DaysOld = 1
$Region = "eu-west-1"

# Arguments from the command line
# Swap 0 and 1 if you want region first, days last
if ($args[0]) {$DaysOld = $args[0]}
if ($args[1]) {$Region = $args[1]}

# Basic input parsing
if (!(Test-Path ($KeyFolder))) {
	Write-Host "`nERROR: Invalid key folder! Edit script and change `$KeyFolder value." -ForegroundColor Yellow
	Write-Host "ERROR: $KeyFolder`n" -ForegroundColor Yellow
	break
}
if ($DaysOld -isnot [int]) {
	Write-Host "`nERROR: Invalid number of days! Value must be integer." -ForegroundColor Yellow
	Write-Host "ERROR: $DaysOld`n" -ForegroundColor Yellow
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
			$Password = $(Get-EC2PasswordData -InstanceId $($Instance.InstanceId) -PemFile $($KeyFolder + "\" + $($Instance.KeyName) + ".pem") -Region $Region)
		}
		catch {
			if ($Instance.State.Name -eq "Terminated") {
				$Password = "* Terminated"
			} else {
				$Password = "* Not available"
			}
		}

		foreach ($Tag in $Instance.Tag | Where-Object {$_.Key -eq "Name"}) {$Name = $Tag.Value}

		$Properties = [ordered]@{
			InstanceId = $Instance.InstanceId
			InstanceName = $Name
			Status = $Instance.State.Name
			PublicIp = $Instance.PublicIpAddress
			PrivateIp = $Instance.PrivateIpAddress
			Password = $Password
			LaunchTime = $LaunchTime
		}
		$Result = New-Object -TypeName psobject -Property $Properties
		$Results = $Results + $Result
	}
}
$Results | Format-Table
