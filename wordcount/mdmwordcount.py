#!/usr/bin/python3.1
#
# Word count script for manuscripts in my particular brand of
# MarkDown format. Might not work for yours.
#
# (c) Urpo Lankinen 2010-11-22
# Permission granted to distribute and modify this script for
# any purpose as long as this copyright notice is retained.
# NO WARRANTY EXPRESSED OR IMPLIED.
#
# [Aside: Especially no assurances that this thing will make you win
# nanowrimo. Those guys have funny methods. =) ]
#

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
