#!/bin/sh

declare OUTFILE=${1:-output.avi}

echo "Capturing to $OUTFILE"

exec /usr/bin/mencoder 'tv://' \
    -tv driver=v4l2:width=768:height=576:outfmt=yuy2:fps=25:alsa -vc rawyuy2 \
    -of avi \
\
    -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1800:vme=0:keyint=250 \
    -oac mp3lame -lameopts cbr:br=64 \
\
    -vf crop=720:544:24:16,pp=lb -sws 1 \
    -o $OUTFILE


# THESE WORK:
#    -ovc xvid -xvidencopts bitrate=900 \
#    -vf crop=720:544:24:16,pp=lb,scale=352:288 -sws 1 \

# THIS WORKS SORTA
#    -ovc lavc -lavcopts vcodec=mjpeg \
#    -oac pcm \

#    -tv driver=v4l2:width=768:height=576:fps=25:alsa \
#    -tv driver=v4l2:width=768:height=576:outfmt=yuy2:fps=25:alsa -vc rawyuy2 \

#    -vf crop=720:544:24:16,pp=lb,scale=352:288 -o $OUTFILE


#exec /usr/bin/mencoder 'tv://' \
#    -tv driver=v4l2:width=768:height=576:outfmt=yuy2:fps=25:alsa -vc rawyuy2 \
#    -of avi \
#\
#    -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1400 \
#    -oac mp3lame -lameopts cbr:br=64 \
#\
#    -vf crop=720:544:24:16,pp=lb -sws 1 \
#    -o $OUTFILE
#
