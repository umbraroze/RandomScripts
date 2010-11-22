#!/usr/bin/ruby

filename = ARGV.shift or fail "Usage: inform2html filename"
fail "#{filename}/Source/story.ni doesn't exist." unless File.exists?(filename+'/Source/story.ni')

puts <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>#{filename}</title>
</head>
<body>
<h1>#{filename}</h1>
<p>
EOF

File.open(filename+'/Source/story.ni') do |f|
  while l = f.gets
    l.chomp!
    l.gsub!(/</,"&lt;");
    l.gsub!(/>/,"&gt;");
    l.gsub!(/&/,"&amp;");
    if(l == '')
      puts "</p>\n<p>"
    else 
      puts l
      puts "<br/>\n"
    end
  end
end

puts <<EOF
</p>
</body>
</html>
EOF
