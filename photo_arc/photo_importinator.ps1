<#
.SYNOPSIS
    A tool for moving photographs from SD cards and Dropbox to NAS.

.DESCRIPTION
    This tool will perform three steps of moving photographs from SD
    cards and dropbox to NAS.

    This program expects to find exiftool.exe on PATH, and expects
    7-Zip to be installed on default location.

    The configuration file (photo_importinator_config.json) should be
    put to $HOME\Documents\WindowsPowerShell\ folkder

.PARAMETER Card
    The SD card drive to import from (e.g. "D:\"). If specified as
    "Dropbox", will import from Dropbox Camera Uploads subfolder in
    current user's home folder instead.

.PARAMETER Camera
    Name of the camera to base the settings on.

.PARAMETER Backup
    The folder where backups should be stored. Can be set in the
    config file; if specified here, will override that value.

.PARAMETER Destination
    The destination folder for the images. Images will be temporarily
    put in subfolder "Incoming".

.PARAMETER Date
    Datestamp for the backup file name. Defaults to current day in
    YYYYMMDD format.

.NOTES
    Filename: photo_importinator.ps1
    Author: Rose Midford
#>

############################################################
# SCRIPT PARAMETERS
############################################################
Param(
    [Parameter(Mandatory=$true)][string]$Camera,
    [string]$Card,
    [string]$Backup,
    [string]$Destination,
    [string]$Date = (Get-Date -Format "yyyyMMdd"),
    [switch]$SkipBackup,
    [switch]$SkipImport,
    [string]$SettingsFile = (Join-Path `
        -Path ([Environment]::GetFolderPath('MyDocuments')+"\WindowsPowerShell\") `
        -ChildPath "photo_importinator_config.json")
)

############################################################
# FUNCTIONS
############################################################

function Write-Line {
    Write-Host -ForegroundColor Cyan ([string]([char]0x2500) * 70)
}
function Write-Box {
    Param([string]$Text)
    if($Text.Length % 2 -ne 0) {
        $Text = $Text + " "
    }
    $spaces = (68/2) - ($Text.Length / 2)
    Write-Host -ForegroundColor Cyan -NoNewline ([char]0x250c)
    Write-Host -ForegroundColor Cyan -NoNewline ([string]([char]0x2500) * 68)
    Write-Host -ForegroundColor Cyan ([char]0x2510)
    Write-Host -ForegroundColor Cyan -NoNewline ([char]0x2502)
    Write-Host -ForegroundColor Red -NoNewline (" " * $spaces)
    Write-Host -ForegroundColor Red -NoNewline $Text
    Write-Host -ForegroundColor Red -NoNewline (" " * $spaces)
    Write-Host -ForegroundColor Cyan ([char]0x2502)
    Write-Host -ForegroundColor Cyan -NoNewline ([char]0x2514)
    Write-Host -ForegroundColor Cyan -NoNewline ([string]([char]0x2500) * 68)
    Write-Host -ForegroundColor Cyan ([char]0x2518)
}

############################################################
# MAIN PROGRAM

# The utilities we need. These can be overridden in the
# config file if needed.
$7zip = "${env:ProgramFiles}\7-Zip\7z.exe"
$exiftool = "exiftool.exe"

# Read the settings.
$settings = Get-Content -Path $SettingsFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

if(-Not $settings.Cameras.$Camera) {
    Write-Error "Can't find camera $Camera in settings"
    Break
}
if($settings.Tools.SevenZip) { $7zip = $settings.Tools.SevenZip }
if($settings.Tools.ExifTool) { $exiftool = $settings.Tools.ExifTool }
if(-Not $Backup) {
    if($settings.Cameras.$Camera.Backup) {
        $Backup = $settings.Cameras.$Camera.Backup
    } else {
        $Backup = $settings.Backup
    }
}
if(-Not $Destination) {
    if($settings.Cameras.$Camera.Destination) {
        $Destination = $settings.Cameras.$Camera.Destination
    } else {
        $Destination = $settings.Destination
    }
}
if($settings.Cameras.$Camera.Card) {
    $Card = $settings.Cameras.$Camera.Card
}

# Print out the banner and the final configuration details.
Write-Box "PHOTO IMPORTINATOR"
Write-Line
Write-Output @"
Settings file:   ${SettingsFile}
Settings:
  Camera:        ${Camera}
  Card:          ${Card}
  Backup folder: ${Backup}
  Destination:   ${Destination}
"@
Write-Line

if (-Not $Card) {
    Write-Error "Card is unspecified"
    Break
}
if (-Not $Backup) {
    Write-Error "Backup folder is unspecified"
    Break
}
if (-Not $Destination) {
    Write-Error "Destination folder is unspecified"
    Break
}

Write-Output "If information isn't correct, press Ctrl+C to abort."
Pause

############################################################

# Figure out input and output destinations
if($Card -eq "Dropbox") {
    Try
    {
        $inputdir = Resolve-Path "${HOME}\Dropbox\Camera Uploads" -ErrorAction Stop
    }
    Catch
    {
        Write-Error "Can't find Dropbox Camera Uploads folder"
        Break
    }        
} else {
    Try
    {
        $cardpath = Resolve-Path $Card -ErrorAction Stop
    }
    Catch [System.Management.Automation.DriveNotFoundException]
    {
        Write-Error "Source card ${Card} doesn't seem to be inserted. Exiting."
        Break
    }
    $inputdir = Join-Path $cardpath "DCIM" -ErrorAction Stop
    if (-Not (Test-Path $inputdir)) {
        Write-Error "Source card ${Card} doesn't seem to have a DCIM folder. Exiting."
        Break
    }
}

# Backup the card contents

if($SkipBackup) {
    Write-Output "⚠️ Skipping backup"
} else {
    Try
    {
        $archive = Join-Path (Resolve-Path $Backup) "${Camera}_${Date}.7z"
    }
    Catch
    {
        Write-Error "Output directory ${Backup} doesn't seem to exist. Exiting."
        Break
    }
    
    Write-Output "Input folder: ${inputdir}"
    Write-Output "Output archive: ${archive}"

    & $7zip a -t7z -r $archive $inputdir 
}

# Move the photos to the Incoming folder, and from there to the desired folder structure.
# (Or should the stuff be actually imported directly from the SD card? I think two steps might
# be safer.)
if($SkipImport) {
    Write-Output "⚠️ Skipping import"
} else {
    # Run ExifTool to import
    Write-Output "Moving the photos from Incoming to the destination folders..."
    $l = Get-Location
    Set-Location -Path $Destination
    & $exiftool
    Set-Location $l
}
