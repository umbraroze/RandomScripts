#!/usr/bin/perl
# ===================================================================
# Sees if there are updates to the software available.
# WWWWolf 2008-01-15.
# Feel free to use/modify/distribute how you want.
# No warranty expressed or implied.
# ===================================================================
# $Id$
# ===================================================================

use strict;
use warnings;

our (%packages);
our $packagefile = $ENV{'HOME'}."/.watchpkgs";

die "Can't find package file $packagefile.\n" unless (-e $packagefile);
die "Can't read package file $packagefile.\n" unless (-r $packagefile);

open(PKGS,$packagefile) or die "Error opening package file $packagefile: $!\n";
while(<PKGS>) {
	chomp;
	next if(/^#/ or $_ eq "");
	$packages{$_} = join ", ", map {/^Version:\s+(.*)/;$1} grep {/^Version:/} split(/\n/, `apt-cache show $_`);
}
close PKGS;

my $package;
foreach $package (sort keys %packages) {
	print $package, ": ", $packages{$package}, "\n";
}
