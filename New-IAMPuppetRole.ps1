######################
# Configuration area #
######################

# Modify names and descriptions of your new policy and role
$PolicyName = "aws-opsworks-cm-puppet"
$PolicyDescription = "Allows adding of OpsWorks Puppet Enterprise nodes"
$RoleName = "aws-opsworks-cm-puppet"
$RoleDescription = "Allows adding of OpsWorks Puppet Enterprise nodes"



##########################################
# Do not change anything below this line #
##########################################

# Version history:
#   2018-03-12 - v1.0 - Initial version
#
# Execute remotely by running:
#   Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/PowerSix/MyPowerShellSpace/master/New-IAMPuppetRole.ps1")
#
# Location and content of the above script may change, so make sure to save the code and call it from a controlled location.

$PolicyDocument = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BUK",
            "Action": [
                "opsworks-cm:AssociateNode",
                "opsworks-cm:DescribeNodeAssociationStatus",
                "opsworks-cm:DescribeServers",
                "ec2:DescribeTags"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
"@

$RoleDocument = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Jinar",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
"@

try {
    Write-Output "Creating IAM policy $PolicyName..."
    $NewPolicy = New-IAMPolicy -PolicyName $PolicyName -PolicyDocument $PolicyDocument -Description $PolicyDescription
    Write-Output "Success!`n"
}
catch {
    Write-Output "Error creating policy!"
    Write-Output $Error[0] | Format-List * -Force
}

try {
    Write-Output "Creating IAM role $RoleName..."
    New-IAMRole -RoleName $RoleName -AssumeRolePolicyDocument $RoleDocument -Description $RoleDescription | Out-Null
    Write-Output "Success!`n"
}
catch {
    Write-Output "Error creating role!"
    Write-Output $Error[0] | Format-List * -Force
}

try {
    Write-Output "Registering IAM policy with role..."
    Register-IAMRolePolicy -RoleName $RoleName -PolicyArn $NewPolicy.Arn
    Write-Output "Success!`n"
}
catch {
    Write-Output "Error registerting policy!"
    Write-Output $Error[0] | Format-List * -Force
}
