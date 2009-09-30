#!/usr/bin/python
# WWWWolf's over-complex WLAN setup script. 2008-06-28
#
# Config file, /root/.start-wlan, should have this stuff:
#
# iface = 'wlan0'
# default_location = 'oulu'
# conf = {
#    'panoulu': {'ssid': 'panoulu'},
#    'myownap': {'ssid': 'supersecrethomenet', 'psk': 'vErYeLiTeStuFF'}
# }

import sys
import os
from getopt import gnu_getopt
import warnings

# Default values.
iface = 'wlan0'
location = None
stop = False
dryrun = False

# Some symlink name magic for defaults...
if(os.path.basename(sys.argv[0]) == 'wup'):
    stop = False
if(os.path.basename(sys.argv[0]) == 'wdown'):
    stop = True

(opts,args)=gnu_getopt(sys.argv[1:],'i:rsn',
                       ['interface=','release','stop','start','dry-run'])
for o in opts:
    if o[0] == '-i' or o[0] == '--interface':
        iface = o[1]
    if o[0] == '-r' or o[0] == '--release' or o[0] == '--stop':
        stop = True
    # "Useful" if this is symlinked as "wdown", so you can do wdown --start.
    # mindboggling!
    if o[0] == '-s' or o[0] == '--start':
        stop = False
    if o[0] == '-n' or o[0] == '--dry-run':
        dryrun = True
if len(args) == 1:
    location = args[0]
if len(args) > 1:
    raise RuntimeError('Too many location arguments.')
if os.geteuid() != 0:
    warnings.warn("You're not root - will do a dry run.")
    dryrun = True

# FIXME: There's *got* to be a better way to form the path.
# Too tired to think straight.
settings_file = '%s%s.start-wlan' % (os.getenv('HOME'),os.sep)
if not os.access(settings_file,os.R_OK):
    raise RuntimeError("Settings file %s can't be read." % settings_file)
execfile(settings_file)

if location == None:
    location = default_location

ssid = conf[location]['ssid']
aptype = 'Open'
psk = None
if conf[location].has_key('psk'):
    aptype = 'WPA'
    psk = conf[location]['psk']

print "\nWWWWolf's horrible WLAN Settings Hack"
print "=====================================\n"
print "Location:", location
print "SSID: %s [%s]" % (ssid,aptype)
print

if dryrun:
    sys.exit()

if stop == False:
    print '>>> Bringing up interface %s' % iface
    os.system('ifconfig %s up' % iface)
    print '>>> Setting %s settings' % iface
    print '  > SSID'
    os.system("iwconfig %s essid '%s'" % (iface,ssid))
    if not psk == None:
        print '  > Auth mode: WPA Pre-share Key'
        os.system("iwpriv %s set AuthMode=WPAPSK" % iface)
        print '  > Setting the pre-share key!'
        os.system("iwpriv %s set 'WPAPSK=%s'" % (iface,psk))
        print '  > Encryption type: TKIP'
        os.system("iwpriv %s set EncrypType=TKIP" % iface)
    print '>>> Interface is set up correctly.'
    print '>>> Get IP address lease via DHCP'
    os.system("dhclient %s" % iface)
    print '>>> Done'
else:
    print '>>> Release IP address lease via DHCP'
    os.system("dhclient %s -r" % iface)
    print '>>> Bringing down interface %s' % iface
    os.system('ifconfig %s down' % iface)
