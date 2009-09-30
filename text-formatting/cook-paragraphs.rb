#!/usr/bin/ruby
# I've probably written a script like this many times. This is one of them.

str = ""

while(a = STDIN.gets) do
	a.chomp!
	if(a != "") then
		str += " " + a.chomp;
	else
		puts "\n"
		puts str[1..-1]
		str = ""
	end
end

puts "\n"
puts str[1..-1]
