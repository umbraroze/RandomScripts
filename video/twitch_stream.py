#!/usr/bin/python
#######################################################################
#
# An utility to invoke FFmpeg to stream stuff from Video4Linux2 capture
# device to Twitch.tv.
#
# You need to copy 'twitch_stream_settings_example.xml' to
# '~/.twitch_stream_settings' and edit it appropriately to get the
# required settings. You need to also get your Twitch.tv
# key (http://www.twitch.tv/broadcast/dashboard/streamkey) and
# put it there.
#
# To invoke:
#   twitch_stream.py                    - Streams to Twitch.
#   twitch_stream.py --dryrun           - Discards stream. Useful for
#                                         benchmarking the encoder performance.
#   twitch_stream.py --file=output.flv  - Captures to file. Useful for
#                                         previewing stream quality.
#
#######################################################################
#
# (c) Urpo Lankinen 2013. I give permission to use this script for any
# purpose as long as this copyright notice is present and unmodified.
# No warranty expressed or implied.
#
#######################################################################

settings_file = '~/.twitch_stream_settings'
ffmpeg_binary = '/usr/bin/ffmpeg'
twitch_rtmp = 'rtmp://live.twitch.tv/app/%s'

#######################################################################

import os
import sys
import getopt
import xml.etree.ElementTree as ET

tree = ET.parse(os.path.expanduser(settings_file))
root = tree.getroot()

output = twitch_rtmp % root.findall('./endpoint/key')[0].text

opts, args = getopt.gnu_getopt(sys.argv[1:], '', ['file=','dryrun'])
for o in opts:
    if '--file' in o:
        output = o[1]
    if '--dryrun' in o:
        output = '/dev/null' # should probably be crossplatform or something?

ffmpeg_params = [
    ffmpeg_binary,
    # Video device.
    '-f', 'video4linux2',
    '-i', root.findall('./video/device')[0].text,
    # General video settings
    '-r', root.findall('./video/framerate')[0].text,
    '-s', root.findall('./video/size')[0].text,
    # Video encoder. We set b:vr=minrate=maxrate to approximate CBR
    '-c:v', 'libx264',
    '-g', root.findall('./video/keyframerate')[0].text,
    '-b:v', root.findall('./video/bitrate')[0].text,
    '-minrate', root.findall('./video/bitrate')[0].text,
    '-maxrate', root.findall('./video/bitrate')[0].text,
    '-bufsize:0', root.findall('./video/buffer')[0].text,
    '-preset', root.findall('./video/preset')[0].text,
    # Audio input
    '-f', 'alsa',
    '-i', root.findall('./audio/device')[0].text,
    '-ar', '44100',
    '-c:a', 'libmp3lame',
    '-b:a', root.findall('./audio/bitrate')[0].text,
    '-bufsize:1', root.findall('./audio/buffer')[0].text,
    # Output stream
    '-f', 'flv',
    '-y',
    output
]

os.execv(ffmpeg_binary,ffmpeg_params)

