#!/usr/bin/perl
# dumps out SID file header (v1) to stderr, and a Vorbis tag to go
# with it to stdout.
# (c) WWWWolf 2005-12-03, do what the hell you want with this, no warranty!

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
