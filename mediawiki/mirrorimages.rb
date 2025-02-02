#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable MediaWiki Image Mirror Script
#
#######################################################################
#
# Copyright (c) 2010 Urpo Lankinen
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

require 'mediawiki_util'
require 'optparse'

$server = 'http://en.wikipedia.org/'
$api = 'http://en.wikipedia.org/w/api.php'
$prefix = nil
$outdir = ""

OptionParser.new do |opts|
  opts.banner = "Usage: lsimages.rb [options] [prefix]"
  opts.on("-S", "--server URL", "Server URL whence you fetch stuff from.",
          "  [default: #{$server} ]") do |x|
    $server = x
  end
  opts.on("-A", "--api URL", "API entry point for the wiki you want to list images on.",
          "  [default: #{$api} ]") do |x|
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

$mw = MediaWikiClient.new($server,$api)
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
  imageinfo = $mw.get_image_info(i,'timestamp|url|user')
  imagerevisions = imageinfo[0]['imageinfo']
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
      ts = MediaWikiClient.parse_date(info['timestamp']).strftime("%Y-%m-%d_%H%M%S")
      user = info['user'].chomp
      target_filename = "#{target_filename}_#{ts}_#{user}"
    end
    # ...and put back the extension and add our target dir
    target_filename = "#{$outdir}#{target_filename}.#{ext}"
    # Skip if already there
    if File.exists?(target_filename)
      puts " - #{info['url'].chomp} [#{info['timestamp'].to_s.chomp}] => #{target_filename} [Already exists!]"
      next
    end
    # Okay, fetch it!
    rescode = $mw.fetch_image_to(info['url'], target_filename, info['timestamp'])
    puts " - #{info['url'].chomp} [#{info['timestamp'].to_s.chomp}] => #{target_filename} [#{rescode == '200' ? 'OK' : 'ERROR '+rescode}]"
  end
end
