#!/usr/bin/ruby1.8
# Hobix to Movable Type Export Format conversion script. Note: Does not deal
# with tags.

require 'find'
require 'yaml'
require 'redcloth'

Find.find("entries") do |file|
	next unless file =~ /\.yaml$/
	#puts "#{file}\n"
	e = YAML::load(File.open(file)).value
	puts "TITLE: #{e['title']}"
	puts "DATE: #{e['created'].strftime('%m/%d/%Y %H:%M:%S')}"
	puts "AUTHOR: #{e['author']}"
	# Grab the category from the file name: entries/foo/bar.yaml => Foo
	file =~ /entries\/(.*?)\//
	pcat = $1.capitalize
	puts "PRIMARY CATEGORY: #{pcat}"
	if e.has_key?('sections')
		e['sections'].each do |s|
			tag = s.capitalize
			puts "CATEGORY: #{tag}" unless tag == pcat
		end
	end
	puts "-----"
	puts "BODY:"
	puts RedCloth.new(e['content']).to_html
	puts "-----"
	puts "--------"
end

