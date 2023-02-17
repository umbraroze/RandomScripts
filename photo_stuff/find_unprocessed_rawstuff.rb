#!/usr/bin/ruby

gem "rubyXL"

require "rubyXL"

counts = {}

workbook = RubyXL::Workbook.new
sheet = workbook[0]
output = ARGV[0] or fail "Usage: ruby scriptname path/to/target.xlsx"

Dir.glob("[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]/*.{NEF,xmp}") do |f|
    match = f.match(/(\d{4})\/(\d{2})\/(\d{2})/)
    y = match[1]; m = match[2]; d = match[3]

    counts[y] ||= {}
    counts[y][m] ||= {}
    counts[y][m][d] ||= {}
    counts[y][m][d][:raws] ||= 0
    counts[y][m][d][:xmps] ||= 0

    if f =~ /NEF$/i then
        counts[y][m][d][:raws] = counts[y][m][d][:raws] + 1    
    elsif  f =~ /xmp$/i then
        counts[y][m][d][:xmps] = counts[y][m][d][:xmps] + 1    
    end

end

sheet.add_cell(0,0,"Date")
sheet.add_cell(0,1,"Raw files")
sheet.add_cell(0,2,"XMP sidecars")

row = 1

counts.keys.sort.each do |y|
    counts[y].keys.sort.each do |m|
        counts[y][m].keys.sort.each do |d|
            puts "#{y}-#{m}-#{d}: #{counts[y][m][d][:raws]} raw files, #{counts[y][m][d][:xmps]} XMP sidecars"
            sheet.add_cell(row,0,"#{y}-#{m}-#{d}")
            sheet.add_cell(row,1,counts[y][m][d][:raws])
            sheet.add_cell(row,2,counts[y][m][d][:xmps])
            row = row + 1
        end
    end
end

workbook.write(output)