#!/usr/bin/ruby
# $Id$
###########################################################################
#
# Capturator
# For managing those #%&@!ng mencoder tv-capture command strings that no
# sane person can ever fully memorise.
#
# "Object orientation done fruitily."
#
# (c) Urpo "WWWWolf" Lankinen 2005
# You can use, modify and distribute this thing without any restrictions,
# just leave this copyright notice here as it is. There is no warranty
# of any kind.
#
###########################################################################

require 'optparse'

###########################################################################
# Global settings

MencoderBinary = '/usr/bin/mencoder'
DefaultVideoFormat = 'yuy2'
DefaultOutputFile = 'output.avi'
DefaultVideoProfile = 'BigMPEG4'
DefaultAudioProfile = 'MP364kCBRAudio'

###########################################################################
# Some class definitions here.

class Profile
  attr :description, false
  attr :codec, false
  attr :options, false

  def codec_option_switch
    fail "Can't do."
  end
  def paramstring
    ret = ''
    @options.keys.each do |o|
      ret = ret + o +
	(@options[o].nil? ? "" : "=" + @options[o]) + ':'
    end
    ret.chop!
  end
  def options
    return [codec_option_switch, paramstring]
  end

  def Profile.profiles_like_this
    if self.superclass != Profile
      return []
    end
    l = []
    ObjectSpace.each_object(Class) do |c|
      if c.superclass == self
	l.push(c)
      end
    end
    return l
  end

end

class VideoProfile < Profile
  attr :filters, false
  attr :videoformat, false

  class VideoFilters
    attr :filters, false
    def initialize
      @filters = [
	[ 'crop', '720:544:24:16' ],
	[ 'pp', 'lb' ]
      ]
    end
    def add(filter, parms)
      @filters.push([filter,parms])
    end
    def paramstring
      ret = ''
      @filters.each do |f|
	if f.length != 2 then
	  fail "incorrectly specified filter filter #{f.inspect}"
	end
	ret = ret + f[0] + 
	  (f[1].nil? ? "" : "=" + f[1]) + ","
      end
      ret.chop!
    end
  end

  def initialize
    @filters = VideoFilters.new
    @videoformat = DefaultVideoFormat
  end

  def codec_option_switch
    case @codec
      when 'lavc' then '-lavcopts'
      when 'xvid' then '-xvidencopts'
    else fail "Unknown codec #{@codec}"
    end
  end
end

class AudioProfile < Profile
  def codec_option_switch
    case @codec
      when 'mp3lame' then '-lameopts'
    else fail "Unknown codec #{@codec}"
    end
  end
end
class TVProfile < Profile
end

def listprofs
  def listp(ct)
    ct.profiles_like_this.each do |c|
      a = c.new
      name = c.name
      desc = a.description
      printf("%-15s %s\n",c.name,a.description)
    end
  end
  puts "\nVideo profiles:"
  listp(VideoProfile)
  puts "\nAudio profiles:"
  listp(AudioProfile)
  puts
  exit
end

###########################################################################
# Video profiles

class BigMPEG4 < VideoProfile
  def initialize
    super()
    @description = "FFMPEG MPEG4 @ 1800kbps, 720x544"
    @codec = 'lavc'
    @options = {
      'vcodec' => 'mpeg4',
      'vbitrate' => '1800',
      'vme' => '0',
      'keyint' => '250'
    }
  end
end
class BigMJPEG < VideoProfile
  def initialize
    super()
    @description = "MJPEG, 720x544"
    @codec = 'lavc'
    @options = {
      'vcodec' => 'mjpeg',
      #'mbd' => '1',
      #'vbitrate' => '1800'
    }
  end
end
class BigHuffYUV < VideoProfile
  def initialize
    super()
    @description = "HuffYUV, 720x544"
    @codec = 'lavc'
    @options = {
      'vcodec' => 'huffyuv'
    }
  end
end
class NetXviD < VideoProfile
  def initialize
    super()
    @description = "XviD @ 900kbps, 352x288"
    @codec = 'xvid'
    @options = {
      'bitrate' => '900',
    }
    @filters.add('scale', '384:288')
  end
  # swscaler = '1'
end
class BigXviD < VideoProfile
  def initialize
    super()
    @description = "XviD @ 1800kbps, 720x544"
    @codec = 'xvid'
    @options = {
      'bitrate' => '1800',
      #'quant_type' => 'mpeg'
    }
    #videoformat = nil
    #tvoptions.delete('outfmt')
  end
end

# Audio profiles

class MP364kCBRAudio < AudioProfile
  def initialize
    super()  
    @description = "LAME MP3, 64kbps constant bitrate"
    @codec = 'mp3lame'
    @options = {
      'cbr' => nil,
      'br' => '64'
    }
  end
end


###########################################################################
# Process the parameters

outputfile = DefaultOutputFile
videoprofile = DefaultVideoProfile
audioprofile = DefaultAudioProfile
videoformat = DefaultVideoFormat
justparms = false

ARGV.options do |opts|
  opts.on("-o", "--output=file.avi", String,
	  "File where the captured video is saved.",
	  "Default: output.avi") { |outputfile| }
  opts.on("-v", "--videoprofile=profile", String,
	  "Which set of video settings to use.",
	  "Default: " + DefaultVideoProfile,
	  "Available: " + VideoProfile.profiles_like_this.join(" ")) do 
    |videoprofile|
  end
  opts.on("-a", "--audioprofile=profile", String,
	  "Which set of audio settings to use.",
	  "Default: " + DefaultAudioProfile,
	  "Available: " + AudioProfile.profiles_like_this.join(" ")) do
    |audioprofile|
  end
  opts.on("-p", "--show-parameters",
	  "Show which mencoder parameters are being used.") {justparms = true}
  opts.on("-l", "--describe-profiles",
          "More detailed information on each of the profiles.") { listprofs }
  opts.on("-h", "--help",
	  "Shows this help message.") { puts opts; exit }
  opts.parse!
end

###########################################################################
# Get our profiles.

vprof = eval("#{videoprofile}.new")
aprof = eval("#{audioprofile}.new")

###########################################################################
# TV settings

class GlobalTVOptions < TVProfile
  def initialize
    super()
    @options = {
      'driver' => 'v4l2',
      'width' => '768',
      'height' => '576',
      'outfmt' => DefaultVideoFormat,
      'fps' => '25',
      'alsa' => nil
    }
  end
end
tvoptions = GlobalTVOptions.new

###########################################################################

# Let's build the option string...
mencoderopts = [
  'tv://',
  '-tv', tvoptions.paramstring,
  '-of', 'avi',
  '-ovc', vprof.codec]
mencoderopts.push(*vprof.options)
mencoderopts.push('-oac', aprof.codec)
mencoderopts.push(*aprof.options)
mencoderopts.push('-vf', vprof.filters.paramstring,
		  '-o', outputfile)

#if not swscaler.nil?
#  mencoderopts.push('-sws', swscaler)
#end

#if (not videoformat.nil?) and videoinformat != 'obey'
#  if videoinformat.nil?
#    mencoderopts.push('-vc','raw' + videoformat)
#  else
#    mencoderopts.push('-vc','raw' + videoinformat)
#  end
#end

# And here is what we finally do.
if justparms
  p mencoderopts
else
  exec MencoderBinary, *mencoderopts
end

# Local variables:
# mode:ruby
# End:
