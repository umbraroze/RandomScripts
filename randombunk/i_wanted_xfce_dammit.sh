#!/bin/sh
#
# Session cleanup script for Debian XFCE.
# By Urpo Lankinen. Basically public domain, because this does so little.
# Note that this will probably be totally unnecessary once I set shit up
# properly (but I'm kind of lazy)

# Fuck PulseAudio.
# Remember to set
#    daemon-binary = /bin/false
# in /etc/pulse/client.conf
pulseaudio -k
killall -9 pulseaudio

# We have the wrong bloody screensaver.
gnome-screensaver-command --exit
xscreensaver-command -exit
xscreensaver -nosplash &



