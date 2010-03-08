#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable MediaWiki Page Lister
# Copyright (C) 2010  Urpo Lankinen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################
#
# This will fetch all image revisions that match the name.
#
# Known issues:
#  - Made to produce small image sets so this will not handle more
#    than 500 images at time. Use prefixes!
#  - No 18n; Assumes File namespace has name File or Image
#  - Error handling isn't very graceful, but it shouldn't blow up too hard
#
#######################################################################

require 'punymediawiki'
require 'optparse'

$api = 'http://en.wikipedia.org/w/api.php'
$prefix = nil
$outdir = ""

OptionParser.new do |opts|
  opts.banner = "Usage: lsimages.rb [options] [prefix]"
  opts.on("-A", "--api URL", "API entry point for the wiki you want to list images on.",
          "  [default: http://en.wikipedia.org/w/api.php ]") do |x|
    $api = x
  end
  opts.on("-d", "--output-directory DIR", "Store images in this directory.",
          "  [default: current directory ]") do |x|
    $outdir = "#{x}/"
  end
end.parse!
$prefix = ARGV.pop if ARGV.length > 0

if $outdir != "" and File.exists?($outdir) and not File.directory?($outdir)
  fail "output directory #{outdir} is not a directory!"
end
if $outdir != "" and not File.exists?($outdir)
  Dir.mkdir($outdir)
end

$mw = MediaWikiClient.new($api)
ns = $mw.get_namespaces
image_ns = nil
ns.each do |n|
  if n['*'] == 'File' or n['*'] == 'Image'
    image_ns = n['id']
    break
  end
end
fail "Couldn't find image namespace!" if image_ns.nil?
#puts "Image namespace is id #{image_ns}"
images = $mw.get_allpages(image_ns,$prefix)
images.each do |i|
  puts "\n#{i}"
  imagerevisions = ($mw.get_image_info(i,'timestamp|url'))[0]['imageinfo']
  next if imagerevisions.length == 0 # Page exists, but no uploaded images
  many_uploads = false
  many_uploads = true if imagerevisions.length > 1
  imagerevisions.each do |info|
    # Pick up file extension
    i =~ /\.([^\.]+)$/
    ext = $1
    # Remove namespace and extension and clean up spaces
    target_filename = i.gsub(/^(File|Image):/,'').gsub(/\.#{ext}$/,'').gsub(/\s+/,'_')
    # Add timestamps to the file name ends if there's multiple revisions
    if many_uploads
      ts = info['timestamp'].chomp
      ts.gsub!(/[^\d]/,'') # Remove nondigits from timestamp
      target_filename = "#{target_filename}_#{ts}"
    end
    # ...and put back the extension and add our target dir
    target_filename = "#{$outdir}#{target_filename}.#{ext}"
    # Okay, fetch it!
    rescode = $mw.fetch_image_to(info['url'], target_filename, info['timestamp'])
    puts " - #{info['url'].chomp} [#{info['timestamp'].to_s.chomp}] => #{target_filename} [#{rescode == '200' ? 'OK' : 'ERROR '+rescode}]"
  end
end
