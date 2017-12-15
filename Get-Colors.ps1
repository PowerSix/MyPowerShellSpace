<#
.SYNOPSIS
	See all the available PowerShell colors.
.DESCRIPTION
    Import in your $PROFILE or dot-source to run Show-Colors and Show-ColorTable for list of colors and foreground/background color information.
.NOTES
    File name : Get-Colors.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 14-Dec-17
	Version   : 2017-12-14 - 1.0 - Initial version.

	Script created as part of a learning tutorial at http://mypowershell.space
	http://mypowershell.space/index.php/2017/12/14/colors-magical-colors/

	More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Expected functionality may be different, so make sure you give the script a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

	This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.EXAMPLE
    . Get-Colors.ps1
	Dot-source the file to gain access to two functions in it. Or just run it for one-off display of both functions.
.EXAMPLE
    Show-Colors
	Shows the list of PowerShell colors, their names and numbers.
.EXAMPLE
    Show-ColorTable
	Shows the matrix of PowerShell foreground/background color information.
.LINK
	http://mypowershell.space
.LINK
	https://github.com/PowerSix/MyPowerShellSpace
#>

function Show-Colors {
    $Colors = [Enum]::GetValues([ConsoleColor])
    $Max = ($Colors | ForEach-Object { "$_".Length } | Measure-Object -Maximum).Maximum
    foreach ($Color in $Colors) {
        Write-Host ("{0, 2} {1, $Max} " -f [int]$Color, $Color) -NoNewline
        Write-Host $Color -Foreground $Color
    }
}

function Show-ColorTable {
    $Colors = $Backgrounds = 0..15
    foreach ($Background in $Backgrounds) {
        foreach ($Color in $Colors) {
            Write-Host ("{0,2},{1,2} " -f $Color, $Background) -ForegroundColor $Color -BackgroundColor $Background -NoNewline
        }
        Write-Host
    }
}

Show-Colors
Show-ColorTable
