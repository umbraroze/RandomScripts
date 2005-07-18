#!/usr/bin/ruby
# $Id$
###########################################################################
#
# Capturator
# For managing those #%&@!ng mencoder tv-capture command strings that no
# sane person can ever fully memorise.
#
# (c) Urpo "WWWWolf" Lankinen 2005
# You can use, modify and distribute this thing without any restrictions,
# just leave this copyright notice here as it is. There is no warranty
# of any kind.
#
###########################################################################

require 'optparse'

# Describe your video and audio profiles here
VideoProfiles = {
  'BigMPEG4' => "FFMPEG MPEG4 @ 1800kbps, 720x544",
  'NetXviD' => "XviD @ 900kbps, 352x288",
  'BigXviD' => "XviD @ 1800kbps, 720x544",
}
AudioProfiles = {
  'MP3-64kCBR' => "LAME MP3, 64kbps constant bitrate"
}

outputfile = 'output.avi'
videoprofile = 'BigMPEG4'
audioprofile = 'MP3-64kCBR'
justparms = false

ARGV.options do |opts|
  opts.on("-o", "--output=file.avi", String,
	  "File where the captured video is saved.",
	  "Default: output.avi") { |outputfile| }
  opts.on("-v", "--videoprofile=profile", String,
	  "Which set of video settings to use.",
	  "Default: BigMPEG4",
	  "Available: " + VideoProfiles.keys.join(" ")) { |videoprofile| }
  opts.on("-a", "--audioprofile=profile", String,
	  "Which set of audio settings to use.",
	  "Default: MP3-64kCBR",
	  "Available: " + AudioProfiles.keys.join(" ")) { |audioprofile| }
  opts.on("-p", "--show-parameters",
	  "Show which mencoder parameters are being used.") {justparms = true}
  opts.on("-h", "--help",
	  "Shows this help message.") { puts opts; exit }
  opts.parse!
end

###########################################################################

def optstostring(opts)
  ret = ''
  opts.keys.each do |o|
    ret = ret + o +
      (opts[o].nil? ? "" : "=" + opts[o]) + ':'
  end
  ret.chop!
  return ret
end

def filterstostring(flts)
  ret = ''
  flts.each do |f|
    if f.length != 2 then
      fail "incorrectly specified filter filter #{f.inspect}"
    end
    ret = ret + f[0] + 
      (f[1].nil? ? "" : "=" + f[1]) + ","
  end
  ret.chop!
  return ret
end

###########################################################################

videocodec = nil
audiocodec = nil
videooptions = nil
audiooptions = nil
vidformat = 'yuy2'
swscaler = nil

VideoCodecOption = {
  'lavc' => '-lavcopts',
  'xvid' => '-xvidencopts'
}
AudioCodecOption = {
  'mp3lame' => '-lameopts'
}

###########################################################################

# Set up your television settings here.
tvoptions = {
  'driver' => 'v4l2',
  'width' => '768',
  'height' => '576',
  'outfmt' => vidformat,
  'fps' => '25',
  'alsa' => nil
}

# These are the filters that are applied to all profiles.
videofilters = [
  [ 'crop', '720:544:24:16' ],
  [ 'pp', 'lb' ]
]

# The video profiles.
case videoprofile
when 'BigMPEG4' then
  videocodec = 'lavc'
  videooptions = {
    'vcodec' => 'mpeg4',
    'vbitrate' => '1800',
    'vme' => '0',
    'keyint' => '250'
  }
when 'NetXviD' then
  videocodec = 'xvid'
  videooptions = {
    'bitrate' => '900',
    'vme' => '0',
    'keyint' => '250'
  }
  videofilters.push(['scale','384:288'])
  swscaler = '1'
when 'BigXviD' then
  videocodec = 'xvid'
  videooptions = {
    'bitrate' => '1800',
    'keyint' => '250'
  }
  vidformat = nil
  tvoptions.delete('outfmt')
end

# THe audio profiles.
case audioprofile
when 'MP3-64kCBR' then
  audiocodec = 'mp3lame'
  audiooptions = {
    'cbr' => nil,
    'br' => '64'
  }
end

###########################################################################

# Let's build the option string...
mencoderopts = [
  '/usr/bin/mencoder',
  'tv://',
  '-tv', optstostring(tvoptions),
  '-of', 'avi',
  '-ovc', videocodec,
  VideoCodecOption[videocodec], optstostring(videooptions),
  '-oac', audiocodec,
  AudioCodecOption[audiocodec], optstostring(audiooptions),
  '-vf',  filterstostring(videofilters),
  '-o', outputfile
]
if not swscaler.nil?
  mencoderopts.push('-sws', swscaler)
end
if not vidformat.nil?
  mencoderopts.push('-vc','raw' + vidformat)
end

# And here is what we finally do.
if justparms
  p mencoderopts
else
  exec mencoderopts
end

# Local variables:
# mode:ruby
# End:
