#!/usr/bin/ruby1.8
#
# Twitter-to-mediawiki page update script that never actually worked.
#
# Should resurrect this one day.
#
#######################################################################

require 'rubygems'
gem     'rwikibot', '>=2.0.0'
require 'rwikibot'
require 'optparse'
require 'twitfetcher'

#######################################################################

exit

bot = RWikiBot.new('USER','PASS','http://www.example.org/w/api.php','',true)

exit


host = 'twitter.com'
twitter_user = nil
cache_file = nil
output_file = nil
format = :mediawiki

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
  opts.on("-f", "--format FORMAT", "Output format. (mediawiki, html)",
          "  [default: mediawiki]") do |x|
    case x 
    when 'mediawiki' then format = :mediawiki
    when 'html' then format = :html
    else fail "Unknown format #{x}"
    end
  end
end.parse!

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
