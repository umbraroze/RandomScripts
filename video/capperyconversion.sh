#!/bin/sh
# Basically, I have a random dc60+ -compatible video cap widget.
# On Mac, videoglide gives me a 640x480 MJPEG video file.
# This script resizes the thing to 854x480 16:9 aspect video, and
# normalises audio volume, using XviD/MP3 codecs.
# Requires ffmpeg and sox. (Latter because ffmpeg doesn't have
# -af to go with -vf yet, and the filter syntax flies well above
# my poor head.)
# Usage:
#  capperyconversion.sh inputfile.mov outputfile.avi

# Extract audio track.
ffmpeg -i $0 -vn -acodec pcm_s16le ex.wav
# Find optimum gain for audio track.
declare GAIN=`sox ex.wav -n stat 2>&1 | grep "Volume adjustment:" | cut -d':' -f2 | tr -d ' '`
# Normalise audio track.
sox ex.wav norm.wav gain $GAIN
rm ex.wav
# Deinterlace and rescale the video. Merge with normalised audio track.
ffmpeg -i $0 -i norm.wav \
    -map 0:0 -map 1:0 \
    -vf "yadif=0:0:0,scale=854:480,setdar=16:9" -aspect 16:9 \
    -vcodec libxvid -vb 1200k \
    -acodec libmp3lame -ab 128k \
    $1
rm norm.wav
