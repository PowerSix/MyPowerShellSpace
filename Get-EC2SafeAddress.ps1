<#
.SYNOPSIS
    Get an AWS Elastic IP address safe from Roskomnadzor righteous crusade.
.DESCRIPTION
    Script user needs ec2:AllocateAddress and ec2:ReleaseAddress IAM permissions to allocate EIPs. If address is in blocked range, release it to the pool and try another one.
.NOTES
    File name : Get-EC2SafeAddress.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-04-18
    Version   : 2018-04-18 - 1.0 - Initial version. Gets Elastic IP and checks if it's blocked. If so, releases and tries another one until success.

    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/04/18/looking-for-safe-aws-elastic-ip-this-may-help

    Blog posts are NOT getting updated! Look for script updates on GitHub!
    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER Region
    Specifies the AWS region for which to obtain a non-blocked Elastic IP. Defaults to eu-west-1.
.PARAMETER Help
    Displays script information and usage.
.EXAMPLE
    Get-EC2SafeAddress.ps1
    Run with no specified parameters. Script uses default, eu-west-1, for region.
.EXAMPLE
    Get-EC2SafeAddress.ps1 -Region us-east-1
    Start looking for an unblocked Elastic IP address in us-east-1 region.
.EXAMPLE
    Get-EC2SafeAddress.ps1 -Help
    Displays detailed script information.
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [string]$Region = "eu-west-1",
    [switch]$Help
)

if ($Help) {
    Write-Host "`nFile name : " -ForegroundColor Cyan -NoNewLine
        Write-host "Get-EC2SafeAddress.ps1" -ForegroundColor Yellow
    Write-Host "Author    : " -ForegroundColor Cyan -NoNewLine
        Write-host "Sinisa Mikasinovic - six@mypowershell.space" -ForegroundColor Yellow
    Write-Host "Blog post : " -ForegroundColor Cyan -NoNewLine
        Write-host "http://mypowershell.space/index.php/2018/04/18/looking-for-safe-aws-elastic-ip-this-may-help" -ForegroundColor Green
    Write-Host "Updates   : " -ForegroundColor Cyan -NoNewLine
        Write-host "https://github.com/PowerSix/MyPowerShellSpace`n" -ForegroundColor Green

    Write-Host "Published : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-04-18" -ForegroundColor Yellow

    Write-Host "Version   : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-04-18 - 1.0 - Initial version. Gets Elastic IP and checks if it's blocked. If so, releases and tries another one until success." -ForegroundColor Yellow

    Write-Host "Examples  : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-EC2SafeAddress.ps1 -Examples" -ForegroundColor Yellow
    Write-Host "Full help : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-EC2SafeAddress.ps1 -Full`n" -ForegroundColor Yellow
    break
}

$BlockedRanges = @("52.58.*.*", "52.59.*.*", "18.194.*.*", "18.195.*.*", "18.196.*.*", "18.197.*.*", "18.184.*.*", "18.185.*.*", "35.156.*.*", "35.157.*.*", "35.158.*.*", "35.159.*.*", "35.192.*.*", "35.193.*.*", "35.194.*.*", "35.195.*.*", "35.196.*.*", "35.197.*.*", "35.198.*.*", "35.199.*.*", "35.200.*.*", "35.201.*.*", "35.202.*.*", "35.203.*.*", "35.204.*.*", "35.205.*.*", "35.206.*.*", "35.207.*.*")

$Success = $false
$ErrorActionPreference = "Stop"

While (!$Success) {
    try {
        $ElasticIp = New-EC2Address -Domain vpc -Region $Region
        $Blocked = $false
    }
    catch {
        Write-Host "Error obtaining the Elastic IP address. " -ForegroundColor Red
        Write-Output $Error[0] | Format-List * -Force
    }

    foreach ($Range in $BlockedRanges) {
        if ($ElasticIp.PublicIp -like $Range) {
            $Blocked = $true
            break
        }
    }

    Write-Host "Elastic IP :: $($ElasticIp.PublicIp) :: " -ForegroundColor Cyan -NoNewline

    if ($Blocked) {
        Write-Host "Blocked! Found in range $Range" -ForegroundColor Yellow
        try {
            Remove-EC2Address -AllocationId $ElasticIp.AllocationId -Region $Region -Force
        }
        catch {
            Write-Host "Unable to remove $($ElasticIp.PublicIp) with allocation ID $($ElasticIp.AllocationId)" -ForegroundColor Red
            Write-Output $Error[0] | Format-List * -Force
        }

    } else {
        Write-Host "Safe! Successsfully allocated in $Region" -ForegroundColor Green
        $Success = $true
    }

}
