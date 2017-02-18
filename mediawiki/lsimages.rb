#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable MediaWiki Page Lister
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
# This will produce a list of images in the wiki in question
#
# Known issues:
#  - Made to produce small image sets so this will not handle more
#    than 500 images at time. Use prefixes!
#  - Error handling isn't very graceful, but it shouldn't blow up too hard
#
#######################################################################

require 'mediawiki_util'
require 'optparse'

$server = 'http://en.wikipedia.org/'
$api = 'http://en.wikipedia.org/w/api.php'
$prefix = nil

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
end.parse!
$prefix = ARGV.pop if ARGV.length > 0

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
  puts i
end
