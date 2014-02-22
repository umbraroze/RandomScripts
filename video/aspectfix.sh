#!/bin/sh
avconv -i $1 -filter:v 'scale=1024:576' -c:v mpeg4 -c:a copy -y -b:v 2400k -aspect 16:9 $2

