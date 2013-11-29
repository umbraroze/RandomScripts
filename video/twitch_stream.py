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
# Additional options:
#   --widescreen                        - Stream in 16:9. If unspecified,
#                                         use 4:3.
#
#######################################################################
#
# (c) Urpo Lankinen 2013. I give permission to use this script for any
# purpose as long as this copyright notice is present and unmodified.
# No warranty expressed or implied.
#
#######################################################################

settings_file = '~/.twitch_stream_settings'
twitch_rtmp = 'rtmp://live.twitch.tv/app/%s'

#######################################################################

import os
import sys
import getopt
import xml.etree.ElementTree as ElementTree

class param:
    def __init__(this,settings):
        this._tree = ElementTree.parse(os.path.expanduser(settings))
        this._root = this._tree.getroot()
    def __getitem__(this,n):
        t = None
        try:
            a = this._root.findall('./%s' % n)
            t = a[0].text
        except IndexError:
            t = None
        return t

param = param(settings_file)

widescreen = False
output = twitch_rtmp % param['endpoint/key']

opts, args = getopt.gnu_getopt(sys.argv[1:], '',
                               ['file=','dryrun','widescreen'])
for o in opts:
    if '--file' in o:
        output = o[1]
    if '--dryrun' in o:
        output = '/dev/null' # should probably be crossplatform or something?
    if '--widescreen' in o:
        widescreen = True

ffmpeg_binary = None
if os.path.exists('/usr/bin/ffmpeg'):
    ffmpeg_binary = '/usr/bin/ffmpeg'
elif os.path.exists('/usr/bin/avconv'):
    ffmpeg_binary = '/usr/bin/avconv'
else:
    ffmpeg_binary = param['encoder']
if ffmpeg_binary == None:
    print("Can't find either ffmpeg or avconv.")
    sys.exit(1)

aspect = '4:3'
if widescreen:
    aspect = '16:9'
size = param['video/size']
if widescreen:
    size = param['video/sizewidescreen']
ffmpeg_params = [
    ffmpeg_binary,
    # Video device.
    '-f', 'video4linux2',
    '-i', param['video/device'],
    # General video settings
    '-r', param['video/framerate'],
    '-s', size,
    '-aspect', aspect,
    # Video encoder. We set b:vr=minrate=maxrate to approximate CBR
    '-c:v', 'libx264',
    '-g', param['video/keyframerate'],
    '-b:v', param['video/bitrate'],
    '-minrate', param['video/bitrate'],
    '-maxrate', param['video/bitrate'],
    '-bufsize:0', param['video/buffer'],
    '-preset', param['video/preset'],
    # Audio input
    '-f', 'alsa',
    '-i', param['audio/device'],
    '-ar', '44100',
    '-c:a', 'libmp3lame',
    '-b:a', param['audio/bitrate'],
    '-bufsize:1', param['audio/buffer'],
    # Output stream
    '-f', 'flv',
    '-y',
    output
]

print(ffmpeg_params)
#os.execv(ffmpeg_binary,ffmpeg_params)


