#!/usr/bin/ruby
#
# This script counts words in an org-mode file subtree. By default, it picks the
# first org-mode headline in the file, and counts words in all headings
# below it. Comments, empty lines and and headlines are ignored.
# To choose an alternate headline, specify it with -h (e.g. -h "Story").
# May be somewhat stupid and buggy and doesn't really take all org-mode
# markup into account at the moment.
#
# © Urpo Lankinen 2011. You are free to use and modify this script for
# any purpose, as long as this copyright notice remains in the file.
# NO WARRANTY expressed or implied.
#

require 'optparse'

# Odious deployment hackery
script = __FILE__
script = File.readlink(script) if File.symlink?(script)
$: << File.dirname(script)
require 'ruby-lib/wordcount'

headline = nil
Usage = "Usage: #{$0} [-h headline] filename.org"
ARGV.options do |opts|
  opts.on("-h", "--headline=str", String,
          "The headline of the subtree to be counted",
          "Default: first headline in the file") { |h| headline = h }
  opts.parse!
end
filename = ARGV.shift or
  fail "Missing filename\n#{Usage}\n"
fail "File \"#{filename}\" not readable" unless File.readable?(filename)

headline_found = false
result = ""
File.open(filename) do |f|
  l = true
  extracting = false
  hit_level = 0
  while(not l.nil?)
    begin
      l = f.readline
    rescue EOFError
      l = nil
    end
    next if l =~ /^#/ # Ignore comments
    next if l =~ /^$/ # Ignore empty lines

    if(l =~ /^(\*+)\s+(.*?)\s*(:\S+?:)?\s*$/) # Matches org headline
      hlevel = $1.length
      hline = $2.chomp
      if $3.nil?
        htags = nil
      else
        htags = $3.chomp
      end
      # Was headline undefined at the start of the program? It is defined now
      headline = hline if(headline.nil?)
      # Is this our headline?
      if headline == hline
        headline_found = true
        # Store the heading level of the headline we're interested of
        hit_level = hlevel
        # Say we're extracting. Please say we're extracting.
        extracting = true
        # Next headline!
        next
      end
      # Did we hit another headline of same or lower level while extracting?
      if extracting and hlevel <= hit_level
        extracting = false
      end
    else # Handle non-heading lines.
      result << l if extracting and not l.nil?
    end
  end
end
unless headline_found
  fail "The headline \"#{headline}\" wasn't found in this file.\n"
end

# FIXME: Currently uses the latex stuff; should probably tweak it to handle
# orgmode text specifically
puts WordCount.count(result,:latex)
