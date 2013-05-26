#!/bin/sh
# Crudely shows the packages that depend on the specified package.
# WILL blow up if there are alternatives, so use carefully. to be useful,
# pipe the output to a file, edit it, and then do
# "apt-get install `cat foo.txt`"
apt-cache show $1 | \
   grep ^Depends: | \
   perl -ne 's/^Depends: //gi; s/\(.*?\),/,/gi; @_ = split /(\s+?)?,(\s+?)?/; print (join "\n", @_), "\n";' | \
   sort | uniq
