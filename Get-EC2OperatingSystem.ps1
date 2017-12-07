<# 
.SYNOPSIS 
    Runs through all instances in a region and gets their parent AMI information.
.DESCRIPTION 
    Run the script to check for the operating system of each instance. If an AMI information is unavailable, "Platform" property will be used to discern between Windows and Linux OS.
.NOTES 
    File name : Get-EC2OperatingSystem.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Date      : 07-Dec-17
    Version   : 1.0 - Initial version
    Script created as part of a learning tutorial at mypowershell.space.
    http://mypowershell.space/index.php/2017/12/07/get-os-of-the-instance-or-gods-forbid-sql-version
    All expected functionality may not be there, make sure you give it a test run first.
    Feel free to update/modify. I'd be interested in seeing it improved.
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.LINK 
    http://mypowershell.space
.EXAMPLE 
    Get-EC2OperatingSystem.ps1
    Runs through all instances in a region and get their parent AMI information.
#>

foreach ($Instance in (Get-EC2Instance).Instances) {
    $Image = Get-EC2Image -ImageId $Instance.ImageId
    if ($Image -eq $null) {
        if ($Instance.Platform -eq "Windows") {
            Write-Output "$($Instance.InstanceId) `t $($Instance.InstanceType) `t AMI information unavailable - Microsoft Windows"
        }
        elseif ($Instance.Platform -eq "") {
            Write-Output "$($Instance.InstanceId) `t $($Instance.InstanceType) `t Unknown"
        }
    }
    else {
        Write-Output "$($Instance.InstanceId) `t $($Instance.InstanceType) `t $($Image.Name) - $($Image.Description)"
    }
}
