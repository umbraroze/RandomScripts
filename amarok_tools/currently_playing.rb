#!/usr/bin/ruby
# Print out the currently playing track from Amarok 2.0.
# WWWWolf 2009-02-09 00:05
# $Id$

require 'dbus'

bus = DBus::SessionBus.instance
amarok = bus.service("org.kde.amarok")
tracklist = amarok.object("/TrackList")
tracklist.introspect
tracklist.default_iface = "org.freedesktop.MediaPlayer"
current_track_no = tracklist.GetCurrentTrack[0]
current_track_metadata = tracklist.GetMetadata(current_track_no)[0]
puts "#{current_track_metadata['artist']} - #{current_track_metadata['title']}"

