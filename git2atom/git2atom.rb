#!/usr/bin/ruby
#####################################################################
# This script will update the "recent work" Atom file (recent.xml).
#
# $Id$
#####################################################################

require 'optparse'
require 'rexml/document'

#####################################################################
# Options

author = {
	'name' => 'Unset Name',
	'email' => 'bogus@example.com'
}
title = "Recent git updates"
id = "http://example.com/bogus/identity/url/"
self_url = "http://example.com/bogus/feed.atom"
output = "updates.atom"
repo = nil

OptionParser.new do |opts|
  opts.banner = "Usage: git2atom.rb [options] repository"
  opts.on("-t", "--title", "Feed title") do |x|
    title = x
  end
  opts.on("-i", "--id", "Feed ID") do |x|
    id = x
  end
  opts.on("-s", "--self", "Feed self link URL") do |x|
    self_url = x
  end
  opts.on("-o", "--output-file", "File to store the feed to [default: updates.atom]") do |x|
    output = x
  end
  opts.on("-n", "--author-name", "Feed author name") do |x|
    author['name'] = x
  end
  opts.on("-e", "--author-email", "Feed author email") do |x|
    author['email'] = x
  end
end.parse!

fail "need repository name" if ARGV.length == 0
repo = ARGV.shift

#####################################################################
# The rest of the program

atomdoc = REXML::Document.new <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	  <title />
	  <id />
  <link href="" rel="self" />
  <author>
    <name />
    <email />
  </author>
  <updated />
</feed>
EOF

current_time = Time.now.gmtime.strftime('%Y-%m-%dT%H:%M:%SZ')

atomdoc.elements["/feed/title"].text = title
atomdoc.elements["/feed/id"].text = id
atomdoc.elements["/feed/link[@rel='self']"].attributes['href'] = self_url
atomdoc.elements["/feed/author/name"].text = author['name']
atomdoc.elements["/feed/author/email"].text = author['email']
atomdoc.elements["/feed/updated"].text = current_time

oldwd = Dir.getwd
Dir.chdir(repo)
entries = nil
open("| git log -n10 --pretty=format:'%H|%ct|%s' | grep -v '|Merge branch'") do |f|
	entries = f.gets(nil).split(/\n/).map{|l| l.split(/\|/,3)}
end
Dir.chdir(oldwd)

#puts entries.inspect
#exit

entries.each do |e|
	en = REXML::Document.new <<EOF
  <entry>
    <title />
    <content type="text" />
    <id />
    <published />
    <updated />
  </entry>
EOF
	en.elements["/entry/id"].text = "urn:githash:#{e[0]}"
	t = Time.at(e[1].to_i).gmtime.strftime('%Y-%m-%dT%H:%M:%SZ')
	en.elements["/entry/published"].text = t
	en.elements["/entry/updated"].text = t
	en.elements["/entry/title"].text = e[2]
	en.elements["/entry/content"].text = e[2]
	atomdoc.elements["/feed"] << en
end

open(output,"w") do |f|
	f.puts(atomdoc.to_s)
end


#####################################################################
# :jEdit:mode=ruby:tabSize=4:indentSize=4:
