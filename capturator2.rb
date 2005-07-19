# This file will be scavenged for the new style of things.
######################################################################

DefaultVideoFormat = 'yuy2'

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

######################################################################
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





ObjectSpace.each_object(Class) do |c|
  if c.superclass == VideoProfile
    a = c.new
    puts "#{c.name}\t#{a.description}\t"
  end
end

