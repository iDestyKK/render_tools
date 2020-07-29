#!/bin/bash
#
# Generate Video Seconds
#
# Description:
#     Takes a video file (any format FFMPEG can handle) and outputs the number
#     of seconds in it. This is pretty useful for generating a "ffmetadata.txt"
#     file for specifying chapters in an MKV.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# Argument check
if [ $# -ne 1 ]; then
	printf "usage: %s video\n" "$0"
	exit 1
fi

# File check
if [ ! -e "$1" ]; then
	printf "fatal: \"%s\" does not exist/\n" "$1"
	exit 2
fi

# ok, do magic
token=$(ffmpeg -i "$1" 2>&1 | grep "Duration" | awk '{ print $2 }')

# Configure sed to extract values
S_EXPR="\([0-9]\+\):\([0-9]\+\):\([0-9]\+\).\([0-9]\+\).*"

# Extract values
T_HOR=$(echo "$token" | sed "s/${S_EXPR}/\1/" | sed 's/^0//') # Hours
T_MIN=$(echo "$token" | sed "s/${S_EXPR}/\2/" | sed 's/^0//') # Minutes
T_SEC=$(echo "$token" | sed "s/${S_EXPR}/\3/" | sed 's/^0//') # Seconds (Whole)
T_SDE=$(echo "$token" | sed "s/${S_EXPR}/\4/") # Seconds (Decimal)

# Compute Seconds
RET=0

let "RET += T_HOR * 3600"
let "RET += T_MIN * 60"
let "RET += T_SEC"
RET="${RET}.${T_SDE}"

echo "$RET"
