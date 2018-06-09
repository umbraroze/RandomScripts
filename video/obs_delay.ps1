############################################################
# A random tool for converting videos from OBS-captured
# stream to delayed audo stream. Will probably not help
# anyone else.
############################################################

param(
    [float]$delay = 0.550,
    [string]$inputfile = "INPUT.flv",
    [string]$outputfile = "OUTPUT.mp4"
)

echo "-------------------------------------------------------------------"
echo "OBS capture to DVD encoder"
echo "-------------------------------------------------------------------"
echo "Command line settings:"
echo " -delay ${delay}"
echo " -inputfile `"${inputfile}`""
echo " -outputfile `"${outputfile}`""
echo "-------------------------------------------------------------------"
echo "If information isn't correct, press Ctrl+C to abort."
Pause

$ffmpeg = $home + "\Applications\ffmpeg-20161221-54931fd-win64-static\bin\ffmpeg.exe";

# To delay video: -map 1:v -map 0:a
# To delay audio: -map 0:v -map 1:a
# Practically: Just pick whatever works, d00d.

& $ffmpeg -y `
    -i $inputfile -itsoffset $delay -i $inputfile -map 1:v -map 0:a `
    -f mp4 -vcodec copy `
    -acodec mp3 `
    $outputfile
