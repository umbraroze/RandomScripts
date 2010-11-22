#!/usr/bin/python2.5
# Count words in a LaTeX document fragment.

import os
import sys

sys.path.append(os.path.join(sys.path[0],'python-lib'))

import wordcounts

if(len(sys.argv) < 2):
    raise RuntimeError("Usage: "+sys.argv[0]+" filename")
filename = sys.argv[1]

print wordcounts.count_words_latex_file(filename)
