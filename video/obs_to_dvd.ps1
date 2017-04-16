############################################################
# A random tool for converting videos from OBS-captured
# stream to DVD. Will probably not help anyone else.
############################################################


param(
    [float]$delay = -0.45,
    [string]$inputfile = "INPUT.flv",
    [string]$outputfile = "OUTPUT.mpg"
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

& $ffmpeg -y -itsoffset $delay -i $inputfile `
    -f dvd -target pal-dvd `
    -vcodec mpeg2video -r 25.00 -aspect 4:3 -b:v 4000k `
    -mbd rd -trellis 1 -flags +mv0 -cmp 2 -subcmp 2 `
    -acodec mp2 -b:a 192k -ar 48000 -ac 2 `
    $outputfile

