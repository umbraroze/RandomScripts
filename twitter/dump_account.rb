#!/usr/bin/ruby1.8
#######################################################################
#
# WWWWolf's Unremarkable Twitter Dump Script.
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

require 'optparse'
require 'twitfetcher'

#######################################################################

host = 'twitter.com'
twitter_user = nil
cache_file = nil
output_file = nil
format = :mediawiki
date_sections = false

OptionParser.new do |opts|
  opts.banner = "Usage: dump_account.rb [options] twitteruser"
  opts.on("-H", "--host HOSTNAME", "Twitter service host name.",
          "  [default: twitter.com]") do |x|
    host = x
  end
  opts.on("-o", "--output-file FILENAME", "File to store the results to.",
          "  [default: printed to stdout]") do |x|
    output_file = x
  end
  opts.on("-c", "--cache-file FILENAME", "Cache file name.",
          "  [default: USERNAME_cache.yaml in current directory]") do |x|
    cache_file = x
  end
  opts.on("-d", "--date-sections", "Produce sections by date.") do |x|
    date_sections = true
  end
  opts.on("-f", "--format FORMAT", "Output format. (mediawiki, html)",
          "  [default: mediawiki]") do |x|
    case x
    when 'mediawiki' then format = :mediawiki
    when 'html' then format = :html
    else fail "Unknown format #{x}"
    end
  end
end.parse!
if date_sections
  case format
  when :mediawiki then format = :mediawiki_by_date
  when :html then format = :html_by_date
  end
end

fail "HTML format is currently unimplemented!" if format == :html

fail "need user name" if ARGV.length == 0
twitter_user = ARGV.shift

cache_file = twitter_user + "_cache.yaml" if cache_file.nil?

STDERR.puts "User name: #{twitter_user}"
STDERR.puts "Cache: #{cache_file}"
if output_file.nil?
  STDERR.puts "Output: (stdout)"
else
  STDERR.puts "Output: #{output_file}"
end

case format
when :mediawiki then STDERR.puts "Format: MediaWiki"
when :html then STDERR.puts "Format: HTML"
when :mediawiki_by_date then STDERR.puts "Format: MediaWiki with date headings"
when :html_by_date then STDERR.puts "Format: HTML with date headings"
else fail "Unknown format somehow slipped past. This is weird!"
end

#######################################################################

tf = TwitFetcher.new(twitter_user, host)
tf.load_cache(cache_file)
tf.fetch!
tf.save_cache(cache_file)

STDERR.puts "Added #{tf.last_new_count} NEW entries out of #{tf.last_fetch_count} retrieved from #{twitter_user} at #{host}"

# Dump to the desired location
o = nil
if output_file.nil?
  o = STDOUT
else
  o = File.open(output_file, 'w')
end
o.puts tf.format(format)
o.close unless output_file.nil?
