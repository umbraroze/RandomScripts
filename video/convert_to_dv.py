#!/usr/bin/python3

# This script doesn't yet do anything. This is just a copypaste of the
# shell scripts that I user right now. The plan is to integrate these
# all to a single Python script.


##### CONVERT EASYCAP TO DV, CORRECT BOGUS ASPECT RATIO

# #!/bin/sh
# 
# in=$1
# bn=`basename $1 .mov`
# outmov="$bn.arfix.mov"
# outdv="$bn.arfix.dv"
# outfdv="$bn.dv"
# outtestfdv="$bn.test.dv"
# 
# ## Two steps. This WORKS, but the raw file is too bloody huge.
# 
# #ffmpeg -i $in -filter:v yadif \
# #              -r 25 \
# #              -aspect 16:9 -codec:v rawvideo -acodec copy \
# #              $outmov
# #ffmpeg -i $outmov -aspect 16:9 -s 720x576 -ar 48000 $outdv
# #rm $outmov
# 
# ## One-step conversion. YADIF doesn't work. produce reasonable quality at all.
# 
# #ffmpeg -i $in \
# #              -filter:v 'yadif=0:0:0' \
# #              -filter:v 'scale=720:576:1' \
# #              -aspect 16:9 \
# #              -r 25 -ar 48000 \
# #              $outdv
# 
# ## Two steps to x264 and DV.
# 
# #ffmpeg -i $in -filter:v yadif \
# #              -r 25 \
# #              -aspect 16:9 -codec:v libx264 -acodec copy -b:v 2400k \
# #              $outmov
# #ffmpeg -i $outmov -filter:v 'scale=720:576' \
# #              -ar 48000 $outfdv
# 
# ## Two steps, piping shit.
# ## Will fail because some idiots had access to the fseek() function
# ## when they were developing formats.
# 
# #ffmpeg -i $in -filter:v yadif \
# #              -r 25 \
# #              -aspect 16:9 -codec:v rawvideo -acodec copy \
# #              -f avi pipe:1 | \
# #ffmpeg -i pipe:0 -aspect 16:9 -s 720x576 -ar 48000 $outdv
# 
# ## One step. See if this comma bastard works.
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
# bn=`basename "$1" .avi`
# outmov="$bn.arfix.mov"
# outdv="$bn.arfix.dv"
# outfdv="$bn.dv"
# outtestfdv="$bn.test.dv"
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
