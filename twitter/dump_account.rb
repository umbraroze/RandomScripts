#!/usr/bin/ruby1.8
#######################################################################

require 'rubygems'
gem('twitter4r', '>=0.3.0')
require 'twitter'
require 'optparse'
require 'yaml'
require 'yaml/store'
require 'cgi'

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

if format == :html
  fail "HTML format is currently unimplemented!"
end

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

# Configure the client.
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

# Read in my cache and build entry hash
entries = {}
last_update = nil
if File.exists?(cache_file)
  e = YAML::load(File.open(cache_file))
  entries = e['entries']
  last_update = e['last_update']
  STDERR.puts "Got #{entries.keys.length} entries from cache. Last update at #{last_update}."
else
  STDERR.puts "Cache file #{cache_file} not found, a new one will be created"
end

# Grab new entries.
grabbed = 0
tl = twitter.timeline_for(:user, :id => twitter_user, :since => last_update, :count => 100) do |status|
  next if entries.has_key?(status.id)
  entries[status.id] = {
    'id' => status.id,
    'time' => status.created_at,
    'text' => status.text
  }
  grabbed += 1
  if last_update.nil?
    last_update = status.created_at
  else
    last_update = status.created_at if last_update >= status.created_at
  end
end

STDERR.puts "Added #{grabbed} NEW entries out of #{tl.length} retrieved from #{twitter_user} at #{host}"

# Save cache.
File.delete(cache_file) if File.exists?(cache_file)
cache = YAML::Store.new(cache_file)
cache.transaction do
  cache['entries'] = entries
  cache['last_update'] = last_update
end

# Dump to the desired location
o = nil
if output_file.nil?
  o = STDOUT
else
  o = File.open(output_file, 'w')
end

o.puts "|-"
o.puts "! Text"
o.puts "! Time"
entries.keys.sort.each do |e|
  # mediawiki format
  en = entries[e]
  o.puts "|-"
  o.puts "| #{CGI.escapeHTML(en['text'])}"
  o.puts "| #{CGI.escapeHTML(en['time'].utc.strftime('%d %B %Y, %H:%M UTC'))}"
end
o.puts "|-"

unless output_file.nil?
  o.close
end
