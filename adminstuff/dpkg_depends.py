#!/usr/bin/python3
# -*- mode:python; coding:utf-8 -*-
###########################################################################
#
# This script will parse dpkg package info (taken from APT) and will
# parse the version numbers required. It can be used for figuring out
# which other packages probably need to be upgraded if you upgrade
# one package.
#
# I had a script like this long ago. I kept forgetting what the
# script was called. So damn me!
#
#
# Changelog:
#   2014-02-22: Initial version
#
###########################################################################
#
# Copyright © 2014 Urpo Lankinen 
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# SOFTWARE IN THE PUBLIC INTEREST, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
###########################################################################

import re
import sys
import locale
import getopt
from subprocess import check_output

encoding = locale.getdefaultlocale()[1]

alternatives_exist = False
goodguess = False
format = 'verbose'

opts, args = getopt.gnu_getopt(sys.argv[1:], '',
                               ['goodguess','format='])
for o in opts:
    if '--goodguess' in o:
        goodguess = True
    if '--format' in o:
        format = o[1]
if not (format in ['verbose','compact','raw']):
    print("format must be either 'verbose', 'compact' or 'raw'")
    exit(1)

package = None
try:
    package = args[0]
except IndexError:
    print("Usage: %s packagename" % sys.argv[0])
    exit(1)




dpkg_output = check_output(['/usr/bin/apt-cache','show',package])

# Get us a list of lines starting with "Depends:" or "Pre-Depends:"
depends = list(filter(lambda x: re.match(r"^(Pre-)?Depends:",x),
                      dpkg_output.decode(encoding).split("\n")))[0]
# Remove the "Depends:" or "Pre-Depends:" bit from the beginning
depends = re.sub(r"^(Pre-)?Depends:\s+","",depends)

def split_list(x):
    return list(map(lambda x: x.strip(), re.split(r",\s*?",x)))
def remove_version(x):
    return re.sub(r"\s*\(.*\)$","",x)
def split_alternatives(x):
    global alternatives_exist
    # I tried to do "if re.match(r"\s*\|\s*",x): ..." here, but Python
    # re module is a fucking moron and can't handle literal pipe
    # character in match(). Works fine in split(), though. Go figure.
    x = re.split(r"\s*\|\s*",x)
    if len(x) == 1:
        return remove_version(x[0])
    else:
        alternatives_exist = True
        return list(map(remove_version,x))

depends = list(map(split_alternatives,split_list(depends)))

# Actual printing out.

if format == 'verbose':
    for p in depends:
        if type(p) is list:
            print(" # Alternatives:")
            for a in p:
                print("    %s" % a)
        else:
            print(" %s" % p)
elif format == 'compact':
    if alternatives_exist:
        print("Package has alternative dependencies, cannot use compact format")
        exit(1)
    print(" ".join(depends))
elif format == 'raw':
    print(depends)
    


