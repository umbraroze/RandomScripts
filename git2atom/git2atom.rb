#!/usr/bin/ruby
#####################################################################
# This script will update the "recent work" Atom file (recent.xml).
#
# $Id$
#####################################################################

# Settings

author = {
	'name' => 'Urpo Lankinen',
	'email' => 'wwwwolf@iki.fi'
}
title = "Recent updates to the Avarthrel site"
id = "urn:wwwwolf:websitefeeds:avarthrelupdates"
self_url = "http://www.iki.fi/wwwwolf/fantasy/avarthrel/updates.atom"
output = "updates.atom"
repo = "/data/scm/git/Avarthrel.git"

#####################################################################

require 'rexml/document'

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
