############################################################
# Take all .flv files in current directory, run them through
# ffmpeg in copy stream mode to convert them to mp4.
# Will make the files better behaved in playback and
# editing (for example, vlc will refuse to seek the flv
# files for no reason at all).
############################################################

## FFmpeg location
#$ffmpeg = $home + "\Applications\ffmpeg\bin\ffmpeg.exe";
$ffmpeg = $env:ProgramFiles + "\FFmpeg\ffmpeg\bin\ffmpeg.exe";

## The meat

$infiles = Get-Item *.flv;
$infiles | ForEach-Object {
    $in = $_;
    $p = Split-Path $in;
    $out = $p  + "\" + $in.BaseName + ".mp4";
    echo "`n`nProcessing $in => $out`n`n";
    & $ffmpeg -i $in -c:v copy -c:a copy $out
}