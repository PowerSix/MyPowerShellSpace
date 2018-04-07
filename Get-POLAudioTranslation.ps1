<#
.SYNOPSIS
    Translate the text into an audio file and play it.
.DESCRIPTION
    Use Amazon Translate to translate the text and feed it into Amazon Polly to get an audio result.
.NOTES
    File name : Get-POLAudioTranslation.ps1
    Author    : Sinisa Mikasinovic - six@mypowershell.space
    Published : 2018-04-06
    Version   : 2018-04-06 - 1.0 - Initial version. Text translation and vocalization from English to other languages enabled. Use -Help for features.

    Scripts are usually created as part of http://mypowershell.space learning tutorials.
    Original post: http://mypowershell.space/index.php/2018/04/06/polly-and-translate-sugar-and-spice

    Blog posts are NOT getting updated! Look for script updates on GitHub!
    More scripts at GitHub: https://github.com/PowerSix/MyPowerShellSpace

    Script execution may differ from expectations. Make sure to give it a test run first.
    Feel free to update/modify. Suggestions and improvements are welcome.

    Obligatory "not my fault if you break stuff" disclaimer:
    This script example is provided "AS IS", without warranties or conditions of any kind, either expressed or implied.
    By using this script, you agree that only you are responsible for any resulting damages, losses, liabilities, costs or expenses.
.PARAMETER Language
    Language that English input text will be translated to. Defaults to the random language.
.PARAMETER Voice
    Voice which Polly will use to speak the translation. Defaults to one of the voices for the selected langugage, if available.
.PARAMETER Text
    The actual text, in English, which is to get translated. Defaults to one of the few example sentences.
.PARAMETER AudioFormat
    Specifies the output audio format. Defaults to mp3, but can be customized to better accomodate your media player.
.PARAMETER AudioPlayer
    Specified the location of your media player. Will attempt to use the default VLC installation if not defined.
.PARAMETER AudioPlayerParameters
    Define your audio player parameters here, such as "hidden window", "exit on finish" and similar.
.PARAMETER AudioDirectory
    Specifies the temporary location for encoded audio files. Defaults to ~ - home.
.PARAMETER AudioTempFile
    Specifies the temporary location of the translated text.
.PARAMETER Quiet
    Prevents Polly from reading the translation. Text translation output only.
.PARAMETER Help
    Displays script information and usage.
.EXAMPLE
    Get-POLAudioTranslation.ps1
    Run with no specified parameters. Uses defaults for language, voice and text selection - all random.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -Language Spanish
    Translates one of default texts to Spanish using randomly one of Polly voices for Spanish language.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -Language French -Voice Joanna
    Uses Joanna's (en-US) voice to read French translation. Mixes like this are in most cases unusable.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -Text "Hello, how are you?" -Language Arabic
    Translates provided text into Arabic. Arabic and Chinese inputs are text only as they don't have a Polly voice.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -Text "It is a nice day" -Language French -Quiet
    Only translates the provided text to French. There is no Polly conversion to audio file.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -AudioPlayer vlc.exe -AudioFormat ogg_vorbis
    Uses a custom audio player to play the translation encoded in .ogg format.
.EXAMPLE
    Get-POLAudioTranslation.ps1 -Help
    Displays detailed script information.
.LINK
    http://mypowershell.space
.LINK
    https://github.com/PowerSix/MyPowerShellSpace
#>

Param(
    [ValidateSet("Spanish", "German", "French", "Portuguese", "Arabic", "Chinese")]
    [string]$Language = $(Get-Random "Spanish", "German", "French", "Portuguese", "Arabic", "Chinese"),
    [ValidateSet("Random", "Nicole", "Enrique", "Tatyana", "Carmen", "Lotte", "Russell", "Geraint", "Mads", "Penelope", "Joanna", "Matthew", "Brian", "Seoyeon", "Maxim", "Ricardo", "Ruben", "Giorgio", "Carla", "Naja", "Astrid", "Maja", "Ivy", "Chantal", "Kimberly", "Amy", "Vicki", "Marlene", "Ewa", "Conchita", "Karl", "Mathieu", "Miguel", "Justin", "Jacek", "Takumi", "Ines", "Cristiano", "Gwyneth", "Mizuki", "Celine", "Jan", "Liv", "Joey", "Filiz", "Dora", "Raveena", "Aditi", "Salli", "Vitoria", "Emma", "Hans", "Kendra")]
    [string]$Voice = "Random",
    [string]$Text = $(Get-Random "Hi, I'm Polly! Nice to meet you!", "Hi, have a great day!"),
    [ValidateSet("mp3", "ogg_vorbis", "pcm")]
    [string]$AudioFormat = "mp3",
    [string]$AudioPlayer = "C:\Program Files\VideoLAN\VLC\vlc.exe",
    [string]$AudioPlayerParameters = "--qt-start-minimized --play-and-exit --qt-notification=0",
    [string]$AudioDirectory = "~",
    [string]$AudioTempFile = "$AudioDirectory\temp.txt",
    [switch]$Quiet,
    [switch]$Help
)

# Display script information and exit
if ($Help) {
	Write-Host "`nFile name : " -ForegroundColor Cyan -NoNewLine
		Write-host "Get-POLAudioTranslation.ps1" -ForegroundColor Yellow
	Write-Host "Author    : " -ForegroundColor Cyan -NoNewLine
		Write-host "Sinisa Mikasinovic - six@mypowershell.space" -ForegroundColor Yellow
	Write-Host "Update    : " -ForegroundColor Cyan -NoNewLine
		Write-host "https://github.com/PowerSix/MyPowerShellSpace`n" -ForegroundColor Green

	Write-Host "Published : " -ForegroundColor Cyan -NoNewLine
		Write-host "2018-04-06" -ForegroundColor Yellow

	Write-Host "Version   : " -ForegroundColor Cyan -NoNewLine
		Write-host "2018-04-06 - 1.0 - Initial version. Text translation and vocalization from English to other languages enabled." -ForegroundColor Yellow

	Write-Host "Examples  : " -ForegroundColor Cyan -NoNewLine
		Write-Host "Get-Help Get-POLAudioTranslation.ps1 -Examples" -ForegroundColor Yellow
	Write-Host "Full help : " -ForegroundColor Cyan -NoNewLine
		Write-Host "Get-Help Get-POLAudioTranslation.ps1 -Full`n" -ForegroundColor Yellow
	break
}

# Check if AWS Tools for Windows PowerShell module is loaded
# Otherwise the initial run is slow, without explanation, while the module loads
$LoadedModules = Get-Module
foreach ($Module in $LoadedModules.Name) {
    if ($Module -eq "AWSPowerShell") {
        $Loaded = $true
        break
    }
}
if (!$Loaded) {
    Write-Host "`nAWSPowerShell module not loaded. Importing... " -ForegroundColor Green -NoNewline
    Import-Module AWSPowerShell
    Write-Host "done!" -ForegroundColor Green
}

if (!(Test-Path -Path $AudioPlayer)) {
    if (!$Quiet) {
        Write-Host "`nInvalid path to media player :: $AudioPlayer" -ForegroundColor Magenta
        Write-Host "Forcing Quiet mode..."
    }
}

Switch ($Language) {
    "Spanish" {
        $PollyLanguage = "es-ES"
        $TRNLanguage = "es"
    }
    "German" {
        $PollyLanguage = "de-DE"
        $TRNLanguage = "de"
    }
    "French" {
        $PollyLanguage = "fr-FR"
        $TRNLanguage = "fr"
    }
    "Portuguese" {
        $PollyLanguage = "pt-PT"
        $TRNLanguage = "pt"
    }
    "Arabic" {
        $PollyLanguage = "N/A"
        $TRNLanguage = "ar"
    }
    "Chinese" {
        $PollyLanguage = "N/A"
        $TRNLanguage = "zh"
    }
}

if ($PollyLanguage -in "N/A", "" -or $Quiet) {
    # Unsupported languages can't be played via Polly
    # Also, -Quiet forces text output only
    $PollyText = ConvertTo-TRNTargetLanguage -Text $Text -SourceLanguageCode en -TargetLanguageCode $TRNLanguage
    Write-Host "`nOriginal text:" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Yellow
    if ($Quiet) {
        Write-Host "`nQuiet mode. $Language translation:" -ForegroundColor Cyan
        Write-Host "$PollyText`n" -ForegroundColor Yellow
    } else {
        Write-Host "`nPolly not available in $Language. Text translation:" -ForegroundColor Cyan
        Write-Host "$PollyText`n" -ForegroundColor Yellow
    }
} else {
    $PollyVoices = Get-POLVoice -LanguageCode $PollyLanguage
    $PollyText = ConvertTo-TRNTargetLanguage -Text $Text -SourceLanguageCode en -TargetLanguageCode $TRNLanguage

    # "~" is set to default home location to support multiple platforms - Will cause issues if unresolved
    $AudioDirectory = Resolve-Path -Path $AudioDirectory
    if (!(Test-Path $AudioDirectory)) {
        try {
            New-Item -ItemType Directory $AudioDirectory | Out-Null
        }
        catch {
            Write-Host "`nInvalid path for temporary files :: $AudioDirectory" -ForegroundColor Magenta
            Write-Host "Exiting..."
            break
        }
    }
    Set-Content -Path $AudioTempFile -Value $PollyText

    # Polly voice selection
    if ($Voice -eq "Random") {
        $RandomVoice = Get-Random -InputObject $PollyVoices
        $PollyVoice = $RandomVoice
    } else {
        $PollyVoice = Get-POLVoice | Where-Object Id -eq $Voice
    }

    # Encode Polly speech into an output file
    $OutputStream = New-Object System.IO.FileStream "$AudioDirectory\$Voice.$AudioFormat", Create
    $AudioText = Get-Content -Path $AudioTempFile
    $AudioSpeech = Get-POLSpeech -Text $AudioText -VoiceId $PollyVoice.Id -OutputFormat $AudioFormat -TextType text
    $AudioSpeech.AudioStream.CopyTo($OutputStream)
    $OutputStream.Close()

    # Display and play final results
    Write-Host "`nOriginal text:" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Yellow
    Write-Host "`n$($PollyVoice.Name) ($($PollyVoice.Gender)/$($PollyVoice.LanguageName)) speaking $($Language):" -ForegroundColor Cyan
    Write-Host "$PollyText`n" -ForegroundColor Yellow
    Start-Process -FilePath $AudioPlayer -ArgumentList "$AudioPlayerParameters ""$AudioDirectory\$Voice.$AudioFormat""" -Wait
    Remove-Item -Path "$AudioDirectory\$Voice.$AudioFormat"
    Remove-Item -Path $AudioTempFile
}
