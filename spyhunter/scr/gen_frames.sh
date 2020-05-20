#!/bin/bash
#
# Generate Frames
#
# Description:
#     Generates PNG files for every frame in a given file "avi" and puts them
#     in a new directory named "frames". This is mainly for manual frame-by-
#     -frame editing that After Effects is somehow not able to do properly.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# Argument Check
if [ $# -ne 1 ]; then
	printf "usage: %s avi\n" "$0"
	exit 1
fi

# Get directory where the AVI file is
D="$(dirname "$1")"

# Check if a "frames" directory already exists
if [ -e "$D/frames" ]; then
	printf "fatal: A \"frames\" directory already exists.\n"
	exit 2
fi

# Easy
mkdir "$D/frames"
ffmpeg -i "$1" "$D/frames/frame%05d.png"
