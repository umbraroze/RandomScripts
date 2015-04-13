#!/usr/bin/ruby
# For creating backup DVD sets of images specified images.
# Creates this sort of file hierarchy:
#  - DVD/YYYY/MM/DD/xxxx.jpg
#  - Later/xxxx.jpg
# The oldest files in the set are put to the DVD in the yearly
# hierarchies. The more recent files that don't fit, and the
# undated files, are put in the "Later" folder.

gem 'mini_exiftool', '~> 2.5.0'

require 'mini_exiftool'

e = MiniExiftool.new('20150410_135838.jpg')
puts DateTime.parse(e.datetimeoriginal.to_s)

