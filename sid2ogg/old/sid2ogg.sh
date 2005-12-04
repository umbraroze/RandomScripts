#!/bin/sh

declare sidfile=$1
declare outfile=$2
declare length=$3
declare subtune=$4

echo "SID file:    $sidfile"
echo "Output file: $outfile"
echo "Length:      $length"
echo "Subtune:     $subtune"

sidplay2 -woutput.wav -t$length $sidfile -o$subtune
sweep output.wav
sid2tag $sidfile > tag.txt
oggenc output.wav
vorbiscomment -w output.ogg $outfile < tag.txt
rm output.wav output.ogg tag.txt
