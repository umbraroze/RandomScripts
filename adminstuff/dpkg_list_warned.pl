#!/usr/bin/perl
#
# Debian utility for finding potentially outdated package definitions.
#
# Basically, I use Debian Unstable, and after a small (but somewhat
# overdue) upgrade of dpkg, dpkg keeps spewing warnings about missing
# architectures in dpkg status database. Some packages are uninstalled
# but have conf files (lazy, I know), some are installed but not
# updated in ages.
#
# This script basically reads dpkg warnings and produces a
# tab-separated list of packages that list the status as
#  I = installed
#  R = removed, config exists
#  U = uninstalled
# and with additional W (e.g. RW) if dpkg also gives a warning about
# that package. So, you can easily search for "RW" to find packages
# that should probably be purged and "IW" for packages that
# probably should be upgraded.

use strict;
use warnings;

system("dpkg -l > /tmp/dpkg.$$.installed.txt 2> /tmp/dpkg.$$.whine.txt");

# Read installed stuff

our (%status,%warned);

open(my $INSTALLED,"</tmp/dpkg.$$.installed.txt") or die;
my ($line);
while($line = <$INSTALLED>) {
    chomp $line;
    next unless $line =~ /^(ii|rc)\s+(.*?)\s/g;
    my $pkgstatus;
    if($1 eq 'ii') {
	$pkgstatus = 'I';
    } elsif($1 eq 'rc') {
	$pkgstatus = 'R';
    }
    my $pkgname = $2;
    $status{$pkgname} = $pkgstatus;
}
close($INSTALLED);
unlink("/tmp/dpkg.$$.installed.txt");

open(my $WHINE,"</tmp/dpkg.$$.whine.txt") or die;
while($line = <$WHINE>) {
    chomp $line;
    next unless $line =~ /dpkg-query: warning:.*package '(.*?)'/g;
    my $pkgname = $1;
    next if(exists $warned{$pkgname});
    $warned{$pkgname} = 1;
    if(exists $status{$pkgname}) {
	$status{$pkgname} = $status{$pkgname}.'W';
    } else {
	$status{$pkgname} = 'UW';
    }
}
close($WHINE);
unlink("/tmp/dpkg/$$.whine.txt");

my $pkgname;
foreach $pkgname (sort keys %status) {
    print $status{$pkgname}."\t$pkgname\n";
}
