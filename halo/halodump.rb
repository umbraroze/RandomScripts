#!/usr/bin/ruby
#
# Quick and dirty Halo: Combat Evolved .map parser/dumper/etc.
#
# Assumes we're reading PC version maps.
#
# Docs for the map format:
# http://www.halodemomods.com/mediawiki/index.php?title=Map_Reading
#

$filename = ARGV.shift or fail "Usage: #{$0} bloodygulchy.map"

unless File.exists?($filename)
  fail "Map file #{$filename} doesn't exist"
end
unless File.readable?($filename)
  fail "Map file #{$filename} isn't readable" 
end

puts "Map file: #{$filename}"

f = File.open($filename,"rb")
# Read header
r = f.read(4)
fail "This doesn't look like a map file to me" unless r == 'daeh'

f.seek(0x588)
r = f.read(2)
version = r.unpack("S>")[0]
puts("Version: #{version}")

f.seek(0x5c2)
r = f.read(20)
puts("Map name: #{r}")

f.seek(0x2c0)
r = f.read(4)
fail "found #{r} (#{r.unpack('H*')[0]}) instead of dehE" unless r == 'dehE'


f.close
