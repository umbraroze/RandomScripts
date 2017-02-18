#!/usr/bin/python3.1
#
# Word count script for manuscripts in my particular brand of
# MarkDown format. Might not work for yours.
#
#######################################################################
#
# Copyright (c) 2010 Urpo Lankinen
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

import os
import sys
import re

def raw_wordcount(string):
    # Split into words along spaces.
    return len(re.split(r'\s+',string))

def processed_wordcount(string):
    s = string
    # Remove excess whitespace.
    s = s.strip() # Remove leading and tailing (aww) whitespace
    s = re.sub(r'\s+',' ',s) # multiple whitespace characters to one space
    # Mess with content.
    s = re.sub(r'\s+---?\s+',' ',s) # Dashes surrounded by spaces into nothing
    s = re.sub(r'(\S)---(\S)',r'\1 \2',s) # Intra---dashes into a space.
    s = re.sub(r"(``|'')",'',s) # rm quotes; might get counted as separate wds
    return raw_wordcount(s)

def count_words_markdown_file(filename):
    f = open(filename,'r')
    contents = f.read()
    f.close()
    raw = raw_wordcount(contents)
    processed = processed_wordcount(contents)
    # how do I shot trinary operator? -guido
    if raw > processed:
        direction = "slack"
    else:
        direction = "excess???"
    # Here are the results.
    print("%s: %d (%d raw; %d %s)\n" % (filename,
                                        processed,
                                        raw,
                                        abs(raw - processed),
                                        direction))

if(len(sys.argv) < 2):
    raise RuntimeError("Usage: "+sys.argv[0]+" filename")
filename = sys.argv[1]

count_words_markdown_file(filename)
