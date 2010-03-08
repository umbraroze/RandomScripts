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
# This will produce a list of images in the wiki in question
#
# Known issues:
#  - Made to produce small image sets so this will not handle more
#    than 500 images at time. Use prefixes!
#  - Error handling isn't very graceful, but it shouldn't blow up too hard
#
#######################################################################

require 'punymediawiki'
require 'optparse'

$api = 'http://en.wikipedia.org/w/api.php'
$prefix = nil

OptionParser.new do |opts|
  opts.banner = "Usage: lsimages.rb [options] [prefix]"
  opts.on("-A", "--api URL", "API entry point for the wiki you want to list images on.",
          "  [default: http://en.wikipedia.org/w/api.php ]") do |x|
    $api = x
  end
end.parse!
$prefix = ARGV.pop if ARGV.length > 0

$mw = MediaWikiClient.new($api)
ns = $mw.get_namespaces
image_ns = nil
ns.each do |n|
  if n['canonical'] == 'File'
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
