#!/usr/bin/ruby
# dumps out SID file header (v1) to stderr, and a Vorbis tag to go
# with it to stdout.
# (c) WWWWolf 2005-12-03, do what the hell you want with this, no warranty!

class HeaderField
  attr :name
  attr :type
  def initialize(name,type)
    @name = name; @type = type
  end
end
class HeaderType
  attr :length
  attr :decodestring
  def initialize(length, decodestring)
    @length = length; @decodestring = decodestring
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


# Main program
filename = ARGV.pop
if filename.nil?
  fail "Please provide file name."
end
fail "File #{filename} doesn't exist." unless File.exists?(filename)
fail "File #{filename} isn't readable." unless File.readable?(filename)

# Read the header.
header = Hash.new
File.open(filename) do |f|
  magic = f.read(4)
  fail "#{filename}: can't find PSID header." unless magic == 'PSID'
  $psid_header.each do |h|
    header[h.name] = f.read(h.type.length).unpack(h.type.decodestring)
  end
end

# Dump the header to stderr.
$psid_header.each do |h|
  if not h.name =~ /address/
    $stderr.puts "#{h.name}: #{header[h.name]}"
  else
    $stderr.printf "%s: %x\n", h.name, header[h.name][0]
  end
end

# Dump the vorbis comment to stdout.
puts "TITLE=#{header['title']}"
puts "ALBUM=#{header['title']}"
puts "ARTIST=#{header['composer']}"
puts "COPYRIGHT=#{header['copyright']}"

