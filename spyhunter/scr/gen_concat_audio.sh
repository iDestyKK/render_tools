#!/bin/bash
#
# Generate Concatenated Audio
#
# Description:
#     Generates a dematrix'd 5.0 master (silent LFE channel) from the audio in
#     the segments for a specific episode. This will be used for generating the
#     5.1 and stereo masters used in the final mixing for each episode.
#
#     Each segment intentionally has FLAC S16 audio for concatentation. This
#     ensures that the masters are lossless until delivery.
#
#     This should be invoked in a part's "root" directory (e.g. "03 - Route
#     Canal"), as it goes into "segments/raw" and generates files for the
#     "audio" directory.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Error Checking                                                           {{{1
# -----------------------------------------------------------------------------

# Argument Check
if [ $# -ne 1 ]; then
	printf "usage: %s dir\n" "$0"
	exit 1
fi

# Directory Check
if [ ! -d "$1" ]; then
	printf "fatal: \"%s\" doesn't exist or isn't a directory\n" "$1"
	exit 2
fi

# Existence of "segments/raw"
if [ ! -d "$1/segments/raw" ]; then
	printf \
		"fatal: \"%s\" doesn't exist or isn't a directory\n" \
		"$1/segments/raw"
	exit 3
fi

# Existence of "audio"
if [ ! -e "audio" ]; then
	mkdir "audio"
fi

# -----------------------------------------------------------------------------
# The Real Deal                                                            {{{1
# -----------------------------------------------------------------------------

cd "$1/segments/raw"

# List creation
echo "file 'intro.mkv'"    > "list.txt"
echo "file 'mission.mkv'" >> "list.txt"
echo "file 'end_mov.mkv'" >> "list.txt"
echo "file 'clear.mkv'"   >> "list.txt"

# Fake blank audio source
NSRC="anullsrc=channel_layout=mono:sample_rate=48000"

# Dematrixing filter for Dolby Pro Logic II Stereo to 5.0 Conversion
FCX1="[0:a]surround=FL|FR|FC|BL|BR[ma]"
FCX2="[ma][1:a]join=inputs=2:channel_layout=5.1[fa]"

# Generate the 5.0 track
ffmpeg \
	-f                 concat            \
	-i                 list.txt          \
	-f                 lavfi             \
	-i                 $NSRC             \
	-vn                                  \
	-filter_complex    "${FCX1};${FCX2}" \
	-map               "[fa]"            \
	-c:a               flac              \
	-compression_level 12                \
	"../../audio/5.0.flac"

# Clean up
rm "list.txt"
