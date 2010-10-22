#!/usr/bin/perl
######################################################################
#
# Random command line hack to bypass the silly tracking URLs in
# Google searches.
#
# Usage: whats_the_damn_url.pl 'hotep://gigantic-google-fruitcake'
#
# © WWWWolf, 2010-10-22.
# Do whatever you want with this script. NO WARRANTY WHATSOEVER.
#
######################################################################

use strict;
use warnings;
use URI;

my ($url, %query, $real_url);

$url = shift or die "Usage: $0 URL\n";
$url = URI->new($url);
die "URL has no query part.\n" unless(defined $url->query);
%query = $url->query_form;
die "URL has no query parameter named 'url'\n" unless(exists $query{'url'});
$real_url = URI->new($query{'url'});
print $real_url->canonical,"\n";
