#!/usr/bin/ruby
# $Id$
# Dumps Amarok song database ratings to HTML file.
# Good for recovering mysteriously mangled files.
# By wwwwolf 2006-12-02. Do what the heck you want this with file. No warranty.

require 'dbi'

database = ARGV.shift
database = "#{ENV['HOME']}/.kde/share/apps/amarok/collection.db" if database.nil?
die "Can't find database" unless File.readable?(database)

STDERR.puts "Using database #{database}"

dbh = DBI.connect('DBI:sqlite3:'+database,'','')

q = dbh.prepare("SELECT url, createdate, accessdate, percentage, rating, playcounter FROM statistics WHERE rating <> 0 ORDER BY url ASC;")
q.execute

puts '<!DOCTYPE HTML "-//W3C//DTD HTML 4.01 Strict//EN//-">'
puts '<html>'
puts '<head><title>Ratings from Amarok database ', database, '</title></head>'
puts '<body>'
puts '<table style="font-size: 8pt;">'
puts '<tr>'
puts '<th>File name</th>'
puts '<th>First</th>'
puts '<th>Last</th>'
puts '<th>Autorating</th>'
puts '<th>Rating</th>'
puts '<th>Playcount</th>'
puts '</tr>'
while row = q.fetch do
  puts '<tr>'
  puts '<td>', File.basename(row['url'])[0..40], '</td>'
  puts '<td>', Time.at(row['createdate'].to_i).to_s, '</td>'
  puts '<td>', Time.at(row['accessdate'].to_i).to_s, '</td>'
  puts '<td>', row['percentage'], '</td>'
  puts '<td>', row['rating'].to_f / 2, '</td>'
  puts '<td>', row['playcounter'].nil? ? "never" : row['playcounter'] , '</td>'
  puts '</tr>'
end
puts '</table>'
puts '</body>'
puts '</html>'

# Buggy driver
#dbh.disconnect
