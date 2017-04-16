############################################################
# A random tool for converting videos from OBS-captured
# stream to DVD. Will probably not help anyone else.
############################################################


param(
    [float]$delay = 0.550,
    [string]$inputfile = "INPUT.flv",
    [string]$outputfile = "OUTPUT.mpg",
    [int]$bitrate = 4000
)

echo "-------------------------------------------------------------------"
echo "OBS capture to DVD encoder"
echo "-------------------------------------------------------------------"
echo "Command line settings:"
echo " -delay ${delay}"
echo " -inputfile `"${inputfile}`""
echo " -outputfile `"${outputfile}`""
echo " -bitrate ${bitrate} [video, kb/s]"
echo "-------------------------------------------------------------------"
echo "If information isn't correct, press Ctrl+C to abort."
Pause

$ffmpeg = $home + "\Applications\ffmpeg-20161221-54931fd-win64-static\bin\ffmpeg.exe";

# To delay video: -map 1:v -map 0:a
# To delay audio: -map 0:v -map 1:a
# Practically: Just pick whatever works, d00d.

& $ffmpeg -y `
    -i $inputfile -itsoffset $delay -i $inputfile -map 1:v -map 0:a `
    -f dvd -target pal-dvd `
    -vcodec mpeg2video -r 25.00 -aspect 4:3 -b:v "${bitrate}k" `
    -mbd rd -trellis 1 -flags +mv0 -cmp 2 -subcmp 2 `
    -acodec mp2 -b:a 192k -ar 48000 -ac 2 `
    $outputfile

