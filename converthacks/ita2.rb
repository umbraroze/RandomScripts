#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# Super-crude ITA2 decoder. This probably looks like it's something I wrote at
# 2 AM while in a headache. Yes, it is just that.

# Slightly retarded parameter handling
mode = :msb_left
if ARGV.length > 0 and (ARGV[0] == "l" or ARGV[0] == "L") then mode = :msb_left end
if ARGV.length > 0 and (ARGV[0] == "r" or ARGV[0] == "R") then mode = :msb_right end

case mode
  when :msb_left then puts "MSB Left"
  when :msb_right then puts "MSB Right"
end

# All-important conversion function
def byteval(x)
  return [("00"+x)].pack("B8")
end

# Our esteemed byte values, basically copypasted off Wikipedia
decodement =
  [["00000", "00000", "[NUL]", "[NUL]"],
   ["00100", "00100", " ", " "],
   ["10111", "11101", "Q", "1"],
   ["10011", "11001", "W", "2"],
   ["00001", "10000", "E", "3"],
   ["01010", "01010", "R", "4"],
   ["10000", "00001", "T", "5"],
   ["10101", "10101", "Y", "6"],
   ["00111", "11100", "U", "7"],
   ["00110", "01100", "I", "8"],
   ["11000", "00011", "O", "9"],
   ["10110", "01101", "P", "0"],
   ["00011", "11000", "A", "-"],
   ["00101", "10100", "S", "[BEL]"],
   ["01001", "10010", "D", "$"],
   ["01101", "10110", "F", "!"],
   ["11010", "01011", "G", "&"],
   ["10100", "00101", "H", "#"], 
   ["01011", "11010", "J", "'"],
   ["01111", "11110", "K", "("],
   ["10010", "01001", "L", ")"],
   ["10001", "10001", "Z", "\""],
   ["11101", "10111", "X", "/"],
   ["01110", "01110", "C", ":"],
   ["11110", "01111", "V", ";"],
   ["11001", "10011", "B", "?"],
   ["01100", "00110", "N", ","],
   ["11100", "00111", "M", "."],
   ["01000", "00010", "[CR]", "[CR]"],
   ["00010", "01000", "[LF]", "[LF]"],
   ["11011", "11011", :numeric, :none],
   ["11111", "11111", :none, :alpha]]

# Here's a moderately clever optimisatotion!!11!
i = 0
while i < decodement.length do
  decodement[i][0] = byteval(decodement[i][0])
  decodement[i][1] = byteval(decodement[i][1])
  i = i + 1
end

# And off to decode stuff
decmode = :alpha
begin
  while l = STDIN.readline
    tokens = l.chomp.split(/\s+/)
    tokens.each do |t|
      fail "Token #{t} doesn't look like a 5-bit binary character." unless t =~ /^[01]{5}$/
      #t = t.reverse if mode == :msb_right
      v = byteval(t)
      decodement.each do |d|
        next unless (mode == :msb_left and d[0] == v) or (mode == :msb_right and d[1] == v)
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
          printf("[A..]")
        elsif c == :numeric
          decmode = :numeric
          printf("[1..]")
        elsif c == :none
          #fail "Redundant mode change"
        else
          printf(c)
        end
      end
    end
  end
rescue EOFError
end
puts

