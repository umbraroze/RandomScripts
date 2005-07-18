#!/usr/bin/ruby
# $Id$

def optstostring(opts)
  ret = ''
  opts.keys.each do |o|
    ret = ret + o +
      (opts[0].nil? ? "" : "=" + opts[o]) + ':'
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

outputfile = 'output.avi'
vidformat = 'yuy2'
wantedvideoformat = 'BigMPEG4'
wantedaudioformat = 'MP3-64kCBR'

VideoCodecOption = {
  'lavc' => '-lavcopts',
  'xvid' => '-xvidencopts'
}
AudioCodecOption = {
  'mp3lame' => '-lameopts'
}

tvoptions = {
  'driver' => 'v4l2',
  'width' => '768',
  'height' => '576',
  'outfmt' => vidformat,
  'fps' => '25',
  'alsa' => nil
}

videocodec = nil
audiocodec = nil
videooptions = nil
audiooptions = nil

videofilters = [
  [ 'crop', '720:544:24:16' ],
  [ 'pp', 'lb' ]
]

case wantedvideoformat
when 'BigMPEG4' then
  videocodec = 'lavc'
  videooptions = {
    'vcodec' => 'mpeg4',
    'vbitrate' => '1800',
    'vme' => '0',
    'keyint' => '250'
  }
end

case wantedaudioformat
when 'MP3-64kCBR' then
  audiocodec = 'mp3lame'
  audiooptions = {
    'cbr' => nil,
    'br' => '64'
  }
end
  

mencoderopts = [
  '/usr/bin/mencoder',
  'tv://',
  '-tv', optstostring(tvoptions),
  '-vc', 'raw' + vidformat,
  '-of', 'avi',
  '-ovc', videocodec,
  VideoCodecOption[videocodec], optstostring(videooptions),
  '-oac', audiocodec,
  AudioCodecOption[audiocodec], optstostring(audiooptions),
  '-vf',  filterstostring(videofilters),
  '-sws', '1',
  '-o', outputfile
]

exec mencoderopts

# Local variables:
# mode:ruby
# End:
