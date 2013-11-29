#!/usr/bin/python3

# This script doesn't yet do anything. This is just a copypaste of the
# shell scripts that I user right now. The plan is to integrate these
# all to a single Python script.

import sys
import os
import re

FFMPEG_BINARY = '/usr/bin/ffmpeg'

def terminate_with_usage():
    print("Usage: convert_to_dv profile inputfile [outputfile]")
    sys.exit()
    
profile = None
inputfile = None
outputfile = None
try:
    profile = sys.argv[1]
except IndexError:
    print("No profile specified")
    terminate_with_usage()
try:
    inputfile = sys.argv[2]
except IndexError:
    print("No input file name specified")
    terminate_with_usage()
try:
    outputfile = sys.argv[3]
except IndexError:
    outputfile = re.sub('\.(mov|avi)$','',inputfile) + '.dv'

print("Profile: %s" % profile)
print("Input: %s" % inputfile)
print("Output: %s" % outputfile)

params = None
if profile == 'easycap_fix_ar':
    params = [
        FFMPEG_BINARY,
        '-i', inputfile,
        outputfile
    ]
elif profile == 'easycap_fix_ar_no_fancy':
    params = [
        FFMPEG_BINARY,
        '-i', inputfile,
        outputfile
    ]
elif profile == 'fraps':
    params = [
        FFMPEG_BINARY,
        '-i', inputfile,
        outputfile
    ]
else:
    print("Unknown profile.")
    sys.exit()

print("Command to invoke: %s" % params)

##### CONVERT EASYCAP TO DV, CORRECT BOGUS ASPECT RATIO

# #!/bin/sh
# 
# in=$1
# outfdv="$bn.dv"
# 
# ffmpeg -i $in -filter:v 'yadif,scale=720:576' \
#               -aspect 16:9 \
#               -r 25 \
#               -ar 48000 \
#               $outfdv
# 

##### CONVERT FRAPS TO DV

# #!/bin/sh
# 
# in="$1"
# outfdv="$bn.dv"
# 
# # using aspect 4:3 for normal videos
# # no yadif because we already have progressive shit.
# ffmpeg -i "$in" -filter:v 'scale=720:576' \
#               -aspect 4:3 \
#               -r 25 \
#               -ar 48000 \
#               "$outfdv"


##### OLD "CAPPERYCONVERSION"

# #!/bin/sh
# # Basically, I have a random dc60+ -compatible video cap widget.
# # On Mac, videoglide gives me a 640x480 MJPEG video file.
# # This script resizes the thing to 854x480 16:9 aspect video, and
# # normalises audio volume, using XviD/MP3 codecs.
# # Requires ffmpeg and sox. (Latter because ffmpeg doesn't have
# # -af to go with -vf yet, and the filter syntax flies well above
# # my poor head.)
# # Usage:
# #  capperyconversion.sh inputfile.mov outputfile.avi
# 
# # Extract audio track.
# ffmpeg -i $0 -vn -acodec pcm_s16le ex.wav
# # Find optimum gain for audio track.
# declare GAIN=`sox ex.wav -n stat 2>&1 | grep "Volume adjustment:" | cut -d':' -f2 | tr -d ' '`
# # Normalise audio track.
# sox ex.wav norm.wav gain $GAIN
# rm ex.wav
# # Deinterlace and rescale the video. Merge with normalised audio track.
# ffmpeg -i $0 -i norm.wav \
#     -map 0:0 -map 1:0 \
#     -vf "yadif=0:0:0,scale=854:480,setdar=16:9" -aspect 16:9 \
#     -vcodec libxvid -vb 1200k \
#     -acodec libmp3lame -ab 128k \
#     $1
# rm norm.wav
# 
