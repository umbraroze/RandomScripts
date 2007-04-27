#!/bin/sh

NETIF="ppp0"
MYIP=`myip`

# clean up.
iptables -F
iptables -X
iptables -Z
ip6tables -F
ip6tables -X
ip6tables -Z
# Set policies.
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Don't allow anyone to connect to these ports from outside.
# smtp
iptables -A INPUT -p tcp -i $NETIF -d $MYIP --dport 25 -j REJECT
# ssh
iptables -A INPUT -p tcp -i $NETIF -d $MYIP --dport 2209 -j REJECT
# mysql
iptables -A INPUT -p tcp -i $NETIF -d $MYIP --dport 3306 -j REJECT
# postgresql
iptables -A INPUT -p tcp -i $NETIF -d $MYIP --dport 5432 -j REJECT
# X11 just in case
iptables -A INPUT -p tcp -i $NETIF -d $MYIP --dport 6000:6100 -j REJECT

# And on IPv6, we *can* talk to HTTP.
ip6tables -A INPUT -p tcp -i $NETIF --dport 80 -j ACCEPT
