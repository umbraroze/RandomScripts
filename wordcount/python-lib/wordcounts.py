#!/usr/bin/python
# Library module for counting words in various methods.
# (Well, eventually, I guess.)

import re

def preprocess_latex_for_word_count(string):
    s = string
    # Remove all LaTeX comments
    s = re.sub(r'%.*?\n',' ',s)
    # Remove excess whitespace.
    s = s.strip() # Remove leading and tailing (aww) whitespace
    s = re.sub(r'\s+',' ',s) # multiple whitespace characters to one space
    # Mess with content.
    s = re.sub(r'\\emph\{([^\}]*?)\}',r'\1',s) # Remove emphasis.
    s = re.sub(r'\\l?dots\{\}','...',s) # Dot dot dot.
    s = re.sub(r'\s+---?\s+',' ',s) # Dashes surrounded by spaces into nothing
    s = re.sub(r'(\S)---(\S)',r'\1 \2',s) # Intra---dashes into a space.
    s = re.sub(r"(``|'')",'',s) # rm quotes; might get counted as separate wds
    return s

def count_words_latex(string):
    s = preprocess_latex_for_word_count(string)
    # Split into words along spaces.
    return len(re.split(r'\s+',s))

def count_words_latex_file(filename):
    f = open(filename,'r')
    contents = f.read()
    f.close()
    return count_words_latex(contents)
