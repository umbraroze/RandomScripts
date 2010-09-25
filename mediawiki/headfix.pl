#!/usr/bin/perl
#
# A random script that will fix MediaWiki-text headings along the lines of
#    == Blah. 1/2/10 ==
# to a more logical format:
#    == Blah. -- January 1, 2010 ==
#
# Bugs: Haven't touched Perl in years, especially since unicode came
# here, so I have no idea how to make it shut up about wide characters in print.
#
# by wwwwolf, 2010-09-26.
# Do what you want with this script; no warranty whatsoever.

use strict;
use warnings;
use Date::Parse;
use Date::Format;
use utf8;

my $line;
while($line = <>) {
    chomp $line;
    if($line =~ m!^==\s*?(.*?)?\s*?(\d+/\d+/\d+)\s*?==$!gi) {
	my $text = $1;
	my $date = time2str("%B %e, %Y",str2time($2));
	$date =~ s/\s+/ /gi;
	if($text ne '') {
	    print("== $text \x{2014} $date ==\n");
	} else {
	    print("== $date ==\n");
	}
    } else {
	print "$line\n";
    }
}
