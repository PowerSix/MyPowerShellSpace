######################
# Configuration area #
######################

# Modify names and descriptions of your new policy and role
$PolicyName = "aws-opsworks-cm-puppet"
$PolicyDescription = "Allows adding of OpsWorks for Puppet Enterprise nodes"
$RoleName = "aws-opsworks-cm-puppet"
$RoleDescription = "Allows adding of OpsWorks for Puppet Enterprise nodes"



##########################################
# Do not change anything below this line #
##########################################

# Version history:
#   2018-04-24 - v1.1 - Fixes to instance role creation
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
                "opsworks-cm:DescribeNodeAssociationStatus"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
"@

# '{"Version":"2012-10-17","Statement":[{"Sid":"Jinar","Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
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

function Show-Error($Message) {
    Write-Output $Message
    if ($Error[0].Message) {
        Write-Output "`nError message: $($Error[0].Message)"
    } elseif ($Error[0].Exception.Message) {
        Write-Output "`nError exception: $($Error[0].Exception.Message)"
    }
    Write-Output "`n`nFull error: "
    Write-Output $Error[0] | Format-List -Force
    break
}

try {
    Write-Output "Creating IAM policy $PolicyName..."
    $NewPolicy = New-IAMPolicy -PolicyName $PolicyName -PolicyDocument $PolicyDocument -Description $PolicyDescription
    Write-Output "Success!`n"
}
catch {
    Show-Error "Error creating policy!"
}

try {
    Write-Output "Creating IAM role $RoleName..."
    New-IAMRole -RoleName $RoleName -AssumeRolePolicyDocument $RoleDocument -Description $RoleDescription | Out-Null
    Write-Output "Success!`n"
}
catch {
    Show-Error "Error creating role!"
}

try {
    Write-Output "Registering IAM policy with role..."
    Register-IAMRolePolicy -RoleName $RoleName -PolicyArn $NewPolicy.Arn
    Write-Output "Success!`n"
}
catch {
    Show-Error "Error registering policy!"
}

try {
    Write-Output "Creating IAM instance profile..."
    $NewInstanceProfile = New-IAMInstanceProfile -InstanceProfileName $RoleName
    Write-Output "Success!`n"
}
catch {
    Show-Error "Error creating profile!"
}

try {
    Write-Output "Adding IAM role to IAM instance profile..."
    Add-IAMRoleToInstanceProfile -RoleName $RoleName -InstanceProfileName $NewInstanceProfile.InstanceProfileName
    Write-Output "Success!`n"
}
catch {
    Show-Error "Error adding role!"
}
