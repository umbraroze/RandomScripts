#!/bin/sh

# 427x240
# 854x480

/usr/bin/ffmpeg \
   -f video4linux2 -r 25 -i /dev/video1 \
   -f alsa -i hw:0 \
   -f mp4 \
   -pix_fmt yuv422p \
   -c:v libx264 -b:v 1200k -g 50 -preset ultrafast \
   -c:a libmp3lame -b:a 64k -bufsize:1 16000k \
   -y /tmp/test.mp4

#/usr/bin/ffmpeg \
#   -f video4linux2 -r 25 -i /dev/video1 \
#   -f alsa -ar 44100 -i hw:0 \
#   -f dv \
#   -y /tmp/test.dv
