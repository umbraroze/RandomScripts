#!/bin/sh

# RAW capture resolution: 720x480
# 16:9 upscaled: 854x480
# 16:9 half-quality: 427x240
# 4:3 low quality: 360x240

/usr/bin/ffmpeg \
   -f video4linux2 -r 25 -i /dev/video1 \
   -f alsa -i hw:1 \
   -f mp4 \
   -pix_fmt yuv422p -filter:v 'yadif,scale=360:240' \
   -c:v libx264 -b:v 1200k -g 50 -preset ultrafast \
   -c:a libmp3lame -b:a 64k -bufsize:1 16000k \
   -y /tmp/test.mp4

#/usr/bin/ffmpeg \
#   -f video4linux2 -r 25 -i /dev/video1 \
#   -f alsa -ar 44100 -i hw:0 \
#   -f dv \
#   -y /tmp/test.dv
