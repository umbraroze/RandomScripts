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
#
# (c) WWWWolf (Urpo Lankinen), 2005-12-03
# wwwwolf@iki.fi / http://www.iki.fi/wwwwolf/
#
# You're free to use this script for any purpose, and expand/tinker with it
# how you want, and distribute it how you want, just keep this copyright
# and attribution here. This thing has NO WARRANTY OF ANY KIND
# (and a sucky error handling to boot)!
#
# This software is an UNMAINTAINED QUICK HACK. You're free to publish 
# your changes, or mail them to me, don't count on me to incorporate
# them on my published version though.
#
######################################################################

require 'optparse'

######################################################################

class PSIDFile
  attr_reader :filename
  attr_reader :header

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

  def initialize(filename)
    set_up_header_structure
    @filename = filename
    decode_header
  end

  private
  def set_up_header_structure
    word = HeaderType.new(2,'n')
    long = HeaderType.new(4,'N')
    string = HeaderType.new(32,'Z32')

    @psid_header = [
      HeaderField.new('psid_version', word),
      HeaderField.new('data_offset', word),
      HeaderField.new('load_address', word),
      HeaderField.new('init_address', word),
      HeaderField.new('play_address', word),
      HeaderField.new('songs', word),
      HeaderField.new('start_song', word),
      HeaderField.new('speed', long),
      HeaderField.new('title', string),
      HeaderField.new('composer', string),
      HeaderField.new('copyright', string)
    ];
  end

  def decode_header
    @header = Hash.new
    File.open(@filename) do |f|
      magic = f.read(4)
      fail "#{@filename}: can't find PSID header." unless magic == 'PSID'
      @psid_header.each do |h|
	@header[h.name] = f.read(h.type.length).unpack(h.type.decode_string)
      end
    end
  end

  public
  def dump_header
    @psid_header.each do |h|
      if not h.name =~ /address/
	puts "#{h.name}: #{@header[h.name]}"
      else
	printf "%s: %x\n", h.name, @header[h.name][0]
      end
    end
  end
end

class SongLength
  attr :seconds
  def initialize(stringrep)
    # If there's a Songlengths.txt qualifier after the time, remove it
    stringrep.gsub!(/\(.*\)$/,"")
    # Parse the time
    if stringrep.index(':').nil?
      # Only seconds
      @seconds = stringrep.to_i
    else
      # min:sec notation
      ln = stringrep.split(/:/,2)
      @seconds = ln[0].to_i * 60 + ln[1].to_i
    end
  end
  def to_s
    as_minsec
  end
  def as_minsec
    s = @seconds % 60
    m = (@seconds - s) / 60
    return (sprintf "%d:%02d", m, s)
  end
  def as_sec
    return @seconds.to_s
  end
end

class SongLengthDatabase
  attr_reader :database

  def initialize(db_file)
    if not File.readable?(db_file)
      fail "Can't read song lenght database from #{db_file}"
    end
    @database = db_file
  end

  # Figure out the subtune lengths.
  def song_lengths_for(filename)
    lengths = nil
    File.open(@database) do |f|
      $_ = ''
      while not $_.nil?
	f.gets
	if not $_.index(filename).nil?
	  f.gets
	  lengths = parse_db_line($_)
	  break
	end
      end
    end
    return lengths
  end
  
  private
  def parse_db_line(l)
    # FORE! Remove trailing linebreak, split to MD5SUM=TIMES, 
    # take the latter, split according to spaces, and make them SongLengths.
    l.chomp.split(/=/,2)[1].split(/ /).collect { |x| SongLength.new(x) }
  end
end

######################################################################
######################################################################
# Main program
######################################################################
######################################################################


######################################################################
# Parse options

OPTIONS = {
  :song_length    => nil,
  :subtune        => nil,
  :output_file    => nil,
  :fadeout_time   => 10,
  :title          => nil,
  :album          => nil,
  :artist         => nil,
  :copyright      => nil,

  :full_sid_file  => nil,
  :sid_file       => nil,
  :hvsc_directory => nil,
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
          "Default: in database") do |x|
    l = SongLength.new(x)
    OPTIONS[:song_length] = l.as_minsec
    OPTIONS[:song_length_sec] = l.as_sec
  end
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
  opts.on("-H", "--hvsc-path=path", String,
          "Path for the HVSC.",
	  "Default: Based on song path") { |OPTIONS[:hvsc_directory]| }

  opts.separator ""

  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }

  # Do the command line parsing NOW...
  opts.parse!
  # ...and pop the full sid file name from the command line.
  OPTIONS[:full_sid_file] = File.expand_path(ARGV.pop)
  # We're done with command line now. Time to mess with the rest.

  # Establish HVSC directory.
  if OPTIONS[:hvsc_directory].nil?
    OPTIONS[:full_sid_file] =~ /(^.*\/C64Music).*/
    OPTIONS[:hvsc_directory] = $1
  end
  # Establish songlength database file location
  if OPTIONS[:song_length_db].nil?
    OPTIONS[:song_length_db] = 
      OPTIONS[:hvsc_directory] + '/DOCUMENTS/Songlengths.txt'
  end
  # Determine file name relative to the HVSC directory.
  OPTIONS[:full_sid_file] =~ /^.*\/C64Music(\/.*)$/
  OPTIONS[:sid_file] = $1

  if OPTIONS[:output_file].nil?
    OPTIONS[:output_file] = File.basename(OPTIONS[:sid_file], ".sid") + ".ogg"
  end
end

######################################################################

# Sanity checking.
if OPTIONS[:full_sid_file].nil?
  fail "Please specify file name!"
end
unless File.exists?(OPTIONS[:full_sid_file])
  fail "Can't find file #{OPTIONS[:full_sid_file]}"
end
unless File.readable?(OPTIONS[:full_sid_file])
  fail "File #{OPTIONS[:full_sid_file]} not readable" 
end

# Parse the PSID file header
hdr = PSIDFile.new(OPTIONS[:full_sid_file])
header = hdr.header

# Figure out the remaining details
if OPTIONS[:subtune].nil?
  OPTIONS[:subtune] = header['start_song'][0]
end
if OPTIONS[:title].nil?
  OPTIONS[:title] = header['title']
end
if OPTIONS[:album].nil?
  OPTIONS[:album] = OPTIONS[:title]
end
if OPTIONS[:artist].nil?
  OPTIONS[:artist] = header['composer']
end
if OPTIONS[:copyright].nil?
  OPTIONS[:copyright] = header['copyright']
end

# Figure out the song length
if OPTIONS[:song_length].nil?
  lengthdb = SongLengthDatabase.new(OPTIONS[:song_length_db])
  lengths = lengthdb.song_lengths_for(OPTIONS[:sid_file])
  if lengths.nil?
    fail "Couldn't find the lengths for #{OPTIONS[:sid_file]} from database "+
      "file #{OPTIONS[:song_length_db]}. Please specify length manually."
  end
  OPTIONS[:song_length]     = lengths[OPTIONS[:subtune] - 1].as_minsec
  OPTIONS[:song_length_sec] = lengths[OPTIONS[:subtune] - 1].as_sec
end

######################################################################
# Actual conversion

puts
puts "SID2OGG by Urpo Lankinen, v1.0, 2005-12-05"
puts "=========================================="
puts

# Print out all of the neat details.
puts "Sidfile: #{OPTIONS[:sid_file]}"
puts "HVSCdir: #{OPTIONS[:hvsc_directory]}"
puts "SongLengthDB: #{OPTIONS[:song_length_db]}"

puts "Output file: #{OPTIONS[:output_file]}"
puts "Subtune: #{OPTIONS[:subtune]}"
puts "Song length: #{OPTIONS[:song_length]} (#{OPTIONS[:song_length_sec]} s)"
puts "Fadeout: #{OPTIONS[:fadeout_time]} s"
puts
puts "Information from the PSID header:"
hdr.dump_header
puts

temp_wav_file = "/tmp/sid2ogg_tmp_#{$$}.wav"
temp_wav_file_faded = "/tmp/sid2ogg_tmp_#{$$}_faded.wav"
temp_tag_file = "/tmp/sid2ogg_tmp_#{$$}_tag.txt"
temp_ogg_file = "/tmp/sid2ogg_tmp_#{$$}.ogg"

# The moment we've all been waiting for...

puts "Playing the file."
system("sidplay2", "-w#{temp_wav_file}", "-t#{OPTIONS[:song_length]}",
       OPTIONS[:full_sid_file], "-o#{OPTIONS[:subtune]}")
puts "Applying fadeout."
system("sox", temp_wav_file, temp_wav_file_faded,
       "fade", 't', '0',
       OPTIONS[:song_length_sec].to_s, OPTIONS[:fadeout_time].to_s)
File.delete(temp_wav_file)
puts "Encoding."
system("oggenc", "-o", temp_ogg_file, temp_wav_file_faded)
File.delete(temp_wav_file_faded)
File.open(temp_tag_file, "w") do |f|
  f.puts "TITLE=#{OPTIONS[:title]}"
  f.puts "ALBUM=#{OPTIONS[:album]}"
  f.puts "ARTIST=#{OPTIONS[:artist]}"
  f.puts "COPYRIGHT=#{OPTIONS[:copyright]}"
end
puts "Tagging."
system("vorbiscomment -w #{temp_ogg_file} #{OPTIONS[:output_file]}"+
       " < #{temp_tag_file}")
File.delete(temp_ogg_file)
File.delete(temp_tag_file)

puts "Done encoding the file to #{OPTIONS[:output_file]}."
