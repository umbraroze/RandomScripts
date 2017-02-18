#!/usr/bin/ruby
# dumps out SID file header (v1) to stderr, and a Vorbis tag to go
# with it to stdout.
#
#######################################################################
#
# Copyright (c) 2005 Urpo Lankinen
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#######################################################################

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
