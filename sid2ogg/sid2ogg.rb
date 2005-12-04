#!/usr/bin/ruby
# $Id$
######################################################################
#
# sid2ogg
# =======
#
# This script will convert a SID file (from HVSC) to Ogg Vorbis.
#
# It will need the following external tools: sidplay2, sox, oggenc
# and vorbiscomment.
#
# Some quirks though:
#  * Nobody bothered to explain me HOW to come up with the MD5sum
#    that is stored in Songlengths. I do "md5sum whatever.sid", get
#    a sum, do "grep thatsumthing Songlengths.txt" and get nothing
#    in return. Every. Single. Time. So this thing instead looks
#    at songlengths comment, ignores the md5sum, and uses the line
#    that follows the comment.
#  * Most of this stuff is really, really, really ugly. Among other
#    things I'm a Perl coder... and it shows. =)
#
######################################################################
# (c) WWWWolf (Urpo Lankinen), 2005-12-03
# wwwwolf@iki.fi / http://www.iki.fi/wwwwolf/
# You're free to use this script for any purpose, and expand/tinker with it
# how you want, and distribute it how you want, just keep this copyright
# and attribution here. This thing has NO WARRANTY OF ANY KIND and a sucky
# error handling to boot!
#
# This software is an UNMAINTAINED QUICK HACK. You're free to publish 
# your changes, or mail them to me, don't count on me to incorporate
# them on my published version though.
######################################################################

require 'optparse'

class HeaderField
  attr :name
  attr :type
  def initialize(name,type)
    @name = name; @type = type
  end
end
class HeaderType
  attr :length
  attr :decode_string
  def initialize(length, decode_string)
    @length = length; @decode_string = decode_string
  end
end

$word = HeaderType.new(2,'n')
$long = HeaderType.new(4,'N')
$string = HeaderType.new(32,'Z32')

$psid_header = [
  HeaderField.new('psid_version', $word),
  HeaderField.new('data_offset', $word),
  HeaderField.new('load_address', $word),
  HeaderField.new('init_address', $word),
  HeaderField.new('play_address', $word),
  HeaderField.new('songs', $word),
  HeaderField.new('start_song', $word),
  HeaderField.new('speed', $long),
  HeaderField.new('title', $string),
  HeaderField.new('composer', $string),
  HeaderField.new('copyright', $string)
];

OPTIONS = {
  :song_length  => nil,
  :subtune      => nil,
  :output_file  => nil,
  :fadeout_time => 10,
  :title        => nil,
  :album        => nil,
  :artist       => nil,
  :copyright    => nil
}

ARGV.options do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: #{script_name} [options] filename"

  opts.separator ""

  opts.on("-s", "--subtune=n", String,
          "What subtune to play.",
          "Default: specified in file") { |x| OPTIONS[:subtune] = x.to_i }
  opts.on("-l", "--length=x:xx", String,
          "Song length, in m:ss or seconds.",
          "Default: in database") { |OPTIONS[:song_length]| }
  opts.on("-o", "--output-file=filename", String,
          "File to store the output to.",
          "Default: <SidName>.ogg") { |OPTIONS[:output_file]| }
  opts.on("-T", "--title=title", String,
          "Override song name.") { |OPTIONS[:title]| }
  opts.on("-L", "--album=title", String,
          "Specify album title.",
	  "Default: Same as song title.") { |OPTIONS[:album]| }
  opts.on("-A", "--artist=artist", String,
          "Override artist.") { |OPTIONS[:artist]| }
  opts.on("-C", "--copyright=copyright", String,
          "Override copyright.") { |OPTIONS[:copyright]| }
  opts.on("-f", "--fadeout=n", String,
	  "Fadeout time in seconds.",
	  "Default: 10") { |x| OPTIONS[:fadeout_time] = x.to_i }

  opts.separator ""

  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }

  opts.parse!
end

full_sid_file = File.expand_path(ARGV.pop)
fail "Please specify file name!" if full_sid_file.nil?
fail "Can't find file #{full_sid_file}" unless File.exists?(full_sid_file)
fail "File #{full_sid_file} not readable" unless File.readable?(full_sid_file)

full_sid_file =~ /(^.*\/C64Music).*/
hvsc_dir = $1
full_sid_file =~ /^.*\/C64Music(\/.*)$/
sid_file = $1

song_length_db = hvsc_dir + '/DOCUMENTS/Songlengths.txt'

puts "Sidfile: #{sid_file}"
puts "HVSCdir: #{hvsc_dir}"
puts "SongLengths: #{song_length_db}"

fail "Can't read song lenght database from #{song_length_db}" unless
  File.readable?(song_length_db)

# Figure out the subtune lengths.
lengths = nil
File.open(song_length_db) do |f|
  $_ = ''
  while not $_.nil?
    f.gets
    if not $_.index(sid_file).nil?
      f.gets
      # FORE! Remove trailing linebreak, split to MD5SUM=TIMES, take latter,
      # Split according to spaces, and then remove x:xx(x) parenthesised parts.
      lengths = $_.chomp.split(/=/,2)[1].split(/ /).collect do |x|
	if x =~ /\(/ then x.gsub!(/\(.*\)$/, "") else x end
      end
      break
    end
  end
end

# Read the header.
header = Hash.new
File.open(full_sid_file) do |f|
  magic = f.read(4)
  fail "#{full_sid_file}: can't find PSID header." unless magic == 'PSID'
  $psid_header.each do |h|
    header[h.name] = f.read(h.type.length).unpack(h.type.decode_string)
  end
end

# Print the header.
$psid_header.each do |h|
  if not h.name =~ /address/
    puts "#{h.name}: #{header[h.name]}"
  else
    printf "%s: %x\n", h.name, header[h.name][0]
  end
end

# Figure out the necessary options
if OPTIONS[:subtune].nil?
  $subtune = header['start_song'][0]
else
  $subtune = OPTIONS[:subtune]
end
if OPTIONS[:song_length].nil?
  $song_length = lengths[$subtune - 1]
else
  $song_length = OPTIONS[:song_length]
end
if $song_length =~ /:/
  sl = $song_length.split(/:/,2)
  $song_length_sec = sl[0].to_i * 60 + sl[1].to_i
else
  $song_length_sec = $song_length.to_i
end
if OPTIONS[:title].nil?
  $title = header['title']
else
  $title = OPTIONS[:title]
end
if OPTIONS[:album].nil?
  $album = $title
else
  $album = OPTIONS[:album]
end
if OPTIONS[:artist].nil?
  $artist = header['composer']
else
  $artist = OPTIONS[:artist]
end
if OPTIONS[:copyright].nil?
  $copyright = header['copyright']
else
  $copyright = OPTIONS[:copyright]
end

if OPTIONS[:output_file].nil?
  $output_file = File.basename(sid_file, ".sid") + ".ogg"
else
  $output_file = OPTIONS[:output_file]
end
$fadeout_time = OPTIONS[:fadeout_time]

puts "Output file: #{$output_file}"
puts "Subtune: #{$subtune}"
puts "Song length: #{$song_length} (#{$song_length_sec} seconds)"
puts "Fadeout: #{$fadeout_time} s"

temp_wav_file = "/tmp/sid2ogg_tmp_#{$$}.wav"
temp_wav_file_faded = "/tmp/sid2ogg_tmp_#{$$}_faded.wav"
temp_tag_file = "/tmp/sid2ogg_tmp_#{$$}_tag.txt"
temp_ogg_file = "/tmp/sid2ogg_tmp_#{$$}.ogg"

puts "Playing the file."
system("sidplay2", "-w#{temp_wav_file}", "-t#{$song_length}",
       full_sid_file, "-o#{$subtune}")
puts "Applying fadeout."
system("sox", temp_wav_file, temp_wav_file_faded,
       "fade", 't', '0', $song_length_sec.to_s, $fadeout_time.to_s)
File.delete(temp_wav_file)
puts "Encoding."
system("oggenc", "-o", temp_ogg_file, temp_wav_file_faded)
File.delete(temp_wav_file_faded)
File.open(temp_tag_file, "w") do |f|
  f.puts "TITLE=#{$title}"
  f.puts "ALBUM=#{$album}"
  f.puts "ARTIST=#{$artist}"
  f.puts "COPYRIGHT=#{$copyright}"
end
puts "Tagging."
system("vorbiscomment -w #{temp_ogg_file} #{$output_file} < #{temp_tag_file}")
File.delete(temp_ogg_file)
File.delete(temp_tag_file)

puts "Done."
