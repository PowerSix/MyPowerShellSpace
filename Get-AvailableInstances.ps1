<#
.SYNOPSIS
    Get the list of available instance types in a particular AWS Region.
.DESCRIPTION
    Use AWS Price List Service to parse a list of all available products and get a list of available instance types.
.NOTES
    File name : Get-AvailableInstances.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-08-13
    Version   : 2018-08-13 - v1.0 - Initial version - Get the list of available instance types in a particular AWS Region

    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/08/13/do-you-need-the-list-of-available-instance-types-in-a-particular-aws-region

    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER InstanceFamily
    Specifies the target instance family - t2, m4, c5, x1. Defaults to t2.
.PARAMETER Region
    Specifies the target AWS region to search - eu-west-1, us-east-1, us-gov-west-1. Use Get-AWSRegion for the full list of regions.
.PARAMETER Simple
    Removes formatting and uses raw output.
.PARAMETER Help
    Displays the script information and usage.
.EXAMPLE
    .\Get-AvailableInstances.ps1
    Runs with no specified parameters. Uses defaults for InstanceFamily and Region (t2 and eu-west-1).
.EXAMPLE
    .\Get-AvailableInstances.ps1 -InstanceFamily m4 -Region us-east-1
    Gets the list of available m4 instances in N. Virginia region.
.EXAMPLE
    .\Get-AvailableInstances.ps1 -InstanceFamily x1 -Region ap-northeast-1 -Simple
    Gets the simple list of available x1 instances in Tokyo region.
.EXAMPLE
    .\Get-AvailableInstances.ps1 -i x1 -r ap-northeast-1 -s
    Same as above, only using parameter aliases.
.EXAMPLE
    .\Get-AvailableInstances.ps1 c5 eu-west-2
    Uses positional arguments. Works, but not recommended.
.EXAMPLE
    .\Get-AvailableInstances.ps1 -Help
    Displays detailed script information.
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [Alias("i", "if")][string]$InstanceFamily = "t2",
    [Alias("r")][string]$Region = "eu-west-1",
    [Alias("s")][switch]$Simple,
    [Alias("h")][switch]$Help
)

# Translate regions to Price List Service format
switch ($Region) {
    {$_ -eq "ap-northeast-1"} {$TargetRegion = "Asia Pacific (Tokyo)"}
    {$_ -eq "ap-northeast-2"} {$TargetRegion = "Asia Pacific (Seoul)"}
    {$_ -eq "ap-northeast-3"} {$TargetRegion = "Asia Pacific (Osaka-Local)"}
    {$_ -eq "ap-south-1"}     {$TargetRegion = "Asia Pacific (Mumbai)"}
    {$_ -eq "ap-southeast-1"} {$TargetRegion = "Asia Pacific (Singapore)"}
    {$_ -eq "ap-southeast-2"} {$TargetRegion = "Asia Pacific (Sydney)"}
    {$_ -eq "ca-central-1"}   {$TargetRegion = "Canada (Central)"}
    {$_ -eq "eu-central-1"}   {$TargetRegion = "EU (Frankfurt)"}
    {$_ -eq "eu-west-1"}      {$TargetRegion = "EU (Ireland)"}
    {$_ -eq "eu-west-2"}      {$TargetRegion = "EU (London)"}
    {$_ -eq "eu-west-3"}      {$TargetRegion = "EU (Paris)"}
    {$_ -eq "sa-east-1"}      {$TargetRegion = "South America (Sao Paulo)"}
    {$_ -eq "us-east-1"}      {$TargetRegion = "US East (N. Virginia)"}
    {$_ -eq "us-east-2"}      {$TargetRegion = "US East (Ohio)"}
    {$_ -eq "us-west-1"}      {$TargetRegion = "US West (N. California)"}
    {$_ -eq "us-west-2"}      {$TargetRegion = "US West (Oregon)"}
    {$_ -eq "us-gov-west-1"}  {$TargetRegion = "AWS GovCloud (US)"}
}

# Display script information and exit
if ($Help) {
    Write-Host "`nFile name : " -ForegroundColor Cyan -NoNewLine
        Write-host "Get-AvailableInstances.ps1" -ForegroundColor Yellow
    Write-Host "Author    : " -ForegroundColor Cyan -NoNewLine
        Write-host "Sinisa Mikasinovic - six@mypowershell.space" -ForegroundColor Yellow
    Write-Host "Blog post : " -ForegroundColor Cyan -NoNewLine
        Write-host "http://mypowershell.space/index.php/2018/08/13/do-you-need-the-list-of-available-instance-types-in-a-particular-aws-region" -ForegroundColor Green
    Write-Host "Updates   : " -ForegroundColor Cyan -NoNewLine
        Write-host "https://github.com/PowerSix/MyPowerShellSpace`n" -ForegroundColor Green

    Write-Host "Published : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-08-13" -ForegroundColor Yellow

    Write-Host "Version   : " -ForegroundColor Cyan -NoNewLine
        Write-host "2018-08-13 - v1.0 - Initial version - Get the list of available instance types in a particular AWS Region" -ForegroundColor Yellow

    Write-Host "Examples  : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help .\Get-AvailableInstances.ps1 -Examples" -ForegroundColor Yellow
    Write-Host "Full help : " -ForegroundColor Cyan -NoNewLine
        Write-Host "Get-Help .\Get-AvailableInstances.ps1 -Full`n" -ForegroundColor Yellow
    break
}

$ProductList = (Get-PLSProduct -ServiceCode AmazonEC2 -Region us-east-1 -Filter @{Type="TERM_MATCH";Field="location";Value="$TargetRegion"},@{Type="TERM_MATCH";Field="preInstalledSw";Value="NA"},@{Type="TERM_MATCH";Field="tenancy";Value="Shared"},@{Type="TERM_MATCH";Field="operatingSystem";Value="Linux"} | ConvertFrom-Json)

$InstanceTypes = @()
foreach ($Product in $ProductList) {
    $InstanceType = $Product.product.attributes.instanceType
    if ($InstanceType -match $InstanceFamily) {
        $InstanceTypes = $InstanceTypes + $InstanceType
    }
}

if (!$Simple) {Write-Output "`nAvailable $($InstanceFamily.ToUpper()) instances in $($Region):"}
Write-Output $InstanceTypes | Sort-Object -Unique
if (!$Simple) {Write-Output " "}
