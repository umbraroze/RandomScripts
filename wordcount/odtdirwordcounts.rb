#!/usr/bin/ruby
#######################################################################
#
# This script will produce a wordcount of all OpenDocument text files
# in current directory. Very quick and dirty. Will soon re-add the
# facility to save the counts to a .csv file.
#
# Requires external program odt2txt to be present in the path. Also
# thinks we're on *nix or something.
# 
#######################################################################
FMT = "%30s     %d\n"
TMPFILE = "/tmp/wordcount.#{Process.pid}.txt"
#STATFILE = "../statistics/focuswriter_counts.csv"
$: << ENV['HOME'] + "/Development/RandomScripts/wordcount"
require 'ruby-lib/wordcount'

puts
total = 0
Dir.open('.').each do |f|
  next unless File.file?(f) and f =~ /\.odt/
  system("odt2txt '#{f}' > #{TMPFILE}")
  n = WordCount.count_in_file(TMPFILE,:latex)
  printf(FMT,f,n)
  total += n
  File.unlink(TMPFILE)
end
puts
printf(FMT,"TOTAL",total)
puts
#File.open(STATFILE,"a") do |f|
#  f.printf("%d,%d\n",Time.now.tv_sec,total)
#end
