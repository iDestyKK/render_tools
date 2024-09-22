#!/bin/bash
#
# Video Copy
#
# Syntax:
#     vid_copy("file.mkv");
#
# Description:
#     Simply puts in "file.mkv" into the video. It is up to you to make sure
#     the video is concatenation-compliant. So it must have matching video and
#     audio track specifications.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Set arguments                                                            {{{1
# -----------------------------------------------------------------------------

ARG_HASH="$1"
ARG_IN_FILE="$2"

echo "HASH: $ARG_HASH"
echo "FILE: $ARG_IN_FILE"
TMP_DIR="__TMP_MKFCSV"

# -----------------------------------------------------------------------------
# Main Function                                                            {{{1
# -----------------------------------------------------------------------------

# Main Function
if [ $# -ne 2 ]; then
	printf "usage: %s hash in.mkv\n" "$0"
	exit 1
fi

cp "$2" "$TMP_DIR/${ARG_HASH}.mkv"
