#!/usr/bin/ruby
#
# This script counts words in an org-mode file subtree. By default, it picks the
# first org-mode headline in the file, and counts words in all headings
# below it. Comments, empty lines and and headlines are ignored.
# Drawers are only counted when -d command line flag is specified.
# To choose an alternate headline, specify it with -H (e.g. -H "Story").
# May be somewhat stupid and buggy and doesn't really take all org-mode
# markup into account at the moment.
#
#######################################################################
#
# Copyright (c) 2011,2012 Urpo Lankinen
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

# Odious deployment hackery
script = __FILE__
script = File.readlink(script) if File.symlink?(script)
$: << File.dirname(script)
require 'ruby-lib/wordcount'

count_drawers = false
headline = nil
Usage = "Usage: #{$0} [-d] [-h headline] filename.org"
ARGV.options do |opts|
  opts.on("-d", "--drawers",
          "Also count the contents of drawers.",
          "Default: drawers not counted") { count_drawers = true }
  opts.on("-H", "--headline=str", String,
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
  within_drawer = false
  while not l.nil?
    begin
      l = f.readline
    rescue EOFError
      l = nil
    end
    next if l =~ /^#/ # Ignore comments
    next if l =~ /^$/ # Ignore empty lines

    if l =~ /^\s*:(\S+):\s*$/ # Matches drawer
      drawer_name = $1
      if drawer_name == "END"
        within_drawer = false
        next
      end
      if (drawer_name != "END" and within_drawer)
        fail "Drawer #{drawer_name} within drawer?!"
      end
      within_drawer = true
      next
    end

    if l =~ /^(\*+)\s+(.*?)\s*(:\S+?:)?\s*$/ # Matches org headline
      hlevel = $1.length
      hline = $2.chomp
      if $3.nil?
        htags = nil
      else
        htags = $3.chomp
      end
      # Was headline undefined at the start of the program? It is defined now
      headline = hline if headline.nil?
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
      next if within_drawer and not count_drawers
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
