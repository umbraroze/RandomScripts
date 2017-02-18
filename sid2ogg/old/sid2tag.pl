#!/usr/bin/perl
# dumps out SID file header (v1) to stderr, and a Vorbis tag to go
# with it to stdout.
#######################################################################
#
# Copyright (c) 2005 Urpo Lankinen
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

use strict;
use warnings;

my $filename = shift or die "Please provide psid file name.\n";

die "$filename doesn't exist\n" unless (-e $filename);
die "Can't read $filename\n" unless (-r $filename);

open(PSIDFILE, $filename) or die "Can't open $filename for reading: $!\n";

my ($readdata, %header);
read PSIDFILE, $readdata, 4;
die "$filename: Can't find PSID header\n" unless $readdata eq 'PSID';

my %header_types = (
		    'psid_version' => 'n',
		    'data_offset' => 'n',
		    'load_address' => 'n',
		    'init_address' => 'n',
		    'play_address' => 'n',
		    'songs' => 'n',
		    'start_song' => 'n',
		    'speed' => 'N',
		    'title' => 'Z*',
		    'composer' => 'Z*',
		    'copyright' => 'Z*'
		   );
my @header_order = ( 'psid_version',
		    'data_offset',
		    'load_address',
		    'init_address',
		    'play_address',
		    'songs',
		    'start_song',
		    'speed',
		    'title',
		    'composer',
		    'copyright',
		   );
my $h;
foreach $h (@header_order) {
  my $format = $header_types{$h};
  my $bytes = 0;
  if($format eq 'n') {
    $bytes = 2;
  } elsif($format eq 'N') {
    $bytes = 4;
  } elsif($format eq 'Z*') {
    $bytes = 32;
  }
  read PSIDFILE, $readdata, $bytes;
  $header{$h} = unpack $format, $readdata;
}

close PSIDFILE;

foreach $h (@header_order) {
  if($h !~ /address/) {
    print STDERR "$h = $header{$h}\n";
  } else {
    printf STDERR '%s = %x', $h, $header{$h};
    print STDERR "\n";
  }
}

# Vorbis header
print "TITLE=", $header{'title'}, "\n";
print "ARTIST=", $header{'composer'}, "\n";
print "ALBUM=", $header{'title'}, "\n";
print "COPYRIGHT=", $header{'copyright'}, "\n";
