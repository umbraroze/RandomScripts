#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Super-crude ITA2 decoder. This probably looks like it's something I wrote at
# 2 AM while in a headache and fixed it the next day without really giving much
# damn at the time. Not the greatest quality code I've written, I admit.

require 'optparse'

$show_mode_changes = false
$byteorder = :msb_left
ARGV.options do |opts|
  opts.banner = "Usage: #{File.basename($0)} [--mode-changes] [--order={left|right}] < input.txt"
  opts.separator ""
  opts.on("-m", "--mode-changes",
          "Show mode changes.",
          "Default: off") { $show_mode_changes = true }
  opts.on("-o", "--order={left|right}", String,
          "Byte ordering, most significant byte on left or right.",
          "Default: left") do |mode|
    case mode.downcase
    when "left" then $byteorder = :msb_left
    when "right" then $byteorder = :msb_right
    else fail "Unknown byte order #{mode.downcase}"
    end
  end
  opts.separator ""
  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }
  opts.parse!
end

# All-important conversion function.
def byteval(x)
  return [x].pack("B5")
end

# Our esteemed byte values, basically copypasted off Wikipedia.
# Columns: Bits in MSB-in-left byteorder, Alpha mode value, Figures mode value.
# In runtime, the the first value will be the actual bit value of the thing, and
# another column will be inserted with MSB-in-right values.
$decodement =
  [["00000", "[NUL]", "[NUL]"],
   ["00100", " ", " "],
   ["10111", "Q", "1"],
   ["10011", "W", "2"],
   ["00001", "E", "3"],
   ["01010", "R", "4"],
   ["10000", "T", "5"],
   ["10101", "Y", "6"],
   ["00111", "U", "7"],
   ["00110", "I", "8"],
   ["11000", "O", "9"],
   ["10110", "P", "0"],
   ["00011", "A", "-"],
   ["00101", "S", "[BEL]"],
   ["01001", "D", "$"],
   ["01101", "F", "!"],
   ["11010", "G", "&"],
   ["10100", "H", "#"], 
   ["01011", "J", "'"],
   ["01111", "K", "("],
   ["10010", "L", ")"],
   ["10001", "Z", "\""],
   ["11101", "X", "/"],
   ["01110", "C", ":"],
   ["11110", "V", ";"],
   ["11001", "B", "?"],
   ["01100", "N", ","],
   ["11100", "M", "."],
   ["01000", "[CR]", "[CR]"],
   ["00010", "[LF]", "[LF]"],
   ["11011", :numeric, :numeric],
   ["11111", :alpha, :alpha]]

# Oh-so-clever optomatitzed runtime expansion of this bullshit
for i in 0..($decodement.length-1) do
  $decodement[i] = $decodement[i].insert(1,$decodement[i][0].reverse)
  $decodement[i][0] = byteval($decodement[i][0])
  $decodement[i][1] = byteval($decodement[i][1])
end

# And off to decode stuff
decmode = :alpha
begin
  while l = STDIN.readline
    tokens = l.chomp.split(/\s+/)
    tokens.each do |t|
      fail "Token #{t} doesn't look like a 5-bit binary character." unless t =~ /^[01]{5}$/
      v = byteval(t)
      $decodement.each do |d|
        next unless
          ($byteorder == :msb_left and d[0] == v) or
          ($byteorder == :msb_right and d[1] == v)
        c = nil
        if decmode == :alpha
          c = d[2]
        elsif decmode == :numeric
          c = d[3]
        else
          fail "What mode is this?"
        end
        if c == :alpha
          decmode = :alpha
          printf("[A..]") if $show_mode_changes
        elsif c == :numeric
          decmode = :numeric
          printf("[1..]") if $show_mode_changes
        else
          printf(c)
        end
      end
    end
  end
rescue EOFError
end
puts

