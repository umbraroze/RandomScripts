#!/usr/bin/ruby1.8
#######################################################################

require 'rubygems'
gem('twitter4r', '>=0.3.0')
require 'twitter'
require 'optparse'

#######################################################################

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
    else
      fail "Unknown format #{x}"
    end
  end
end.parse!

fail "need user name" if ARGV.length == 0
twitter_user = ARGV.shift

if cache_file.nil?
  cache_file = twitter_user + "_cache.yaml"
end

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
else
  fail "Unknown format somehow slipped past. This is weird!"
end

#######################################################################
Twitter::Client.configure do |conf|
  conf.protocol = :http
  conf.host = host
  conf.port = 80

  conf.user_agent = 'WWWWolfsRandomTwitterDumpScript/1.0'
  conf.application_name = 'WWWWolfsRandomTwitterDumpScript'
  conf.application_version = 'v1.0'
  conf.application_url = 'http://github.com/wwwwolf/randomscripts'
end

twitter = Twitter::Client.new

public_timeline = twitter.timeline_for(:user, :id => twitter_user) do |status|
  puts status.user.screen_name, status.text
end
