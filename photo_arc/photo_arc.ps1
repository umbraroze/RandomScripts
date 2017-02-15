############################################################
# PowerShell script for archiving photographs.
# Uses 7-Zip.
############################################################

param (
    # Card device
    [string]$card = "F:\",
    # Where will we store the output file?
    [string]$outputdir = "D:\",
    # What's the camera name?
    [string]$camera = "Nikon_D3200"
)

echo "-------------------------------------------------------------------"
echo "Photo archival tool"
echo "Creating a dated 7zip archive of the photos on the SD card."
echo "-------------------------------------------------------------------"
echo "Command line settings:"
echo " -card `"${card}`""
echo " -outputdir `"${outputdir}`""
echo " -camera `"${camera}`""
echo "-------------------------------------------------------------------"
echo "If information isn't correct, press Ctrl+C to abort."
Pause

############################################################
# Add location of 7z.exe to the path
$env:Path += ";c:\Program Files\7-Zip";

# Figure out input and output destinations
Try
{
    $inputdir = Join-Path (Resolve-Path $card) "DCIM"
}
Catch
{
    echo "Source card ${card} doesn't seem to have a DCIM folder. Exiting."
    Break
}
$datestamp = Get-Date -format "yyyyMMdd"
Try
{
    $archive = Join-Path (Resolve-Path $outputdir) "${camera}_${datestamp}.7z"
}
Catch
{
    echo "Output directory ${outputdir} doesn't seem to exist. Exiting."
    Break
}

echo "Input folder: ${inputdir}"
echo "Output archive: $archive"

& 7z a -t7z -r $archive $inputdir 




