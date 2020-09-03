#!/bin/bash
#
# FFMPEG-powered Zoom Recording Reorganiser
#
# Description:
#     Creates a final MKV media file when given an OBS recording, a directory,
#     and a chat log from Zoom. The video stream from the OBS recording is
#     used. For audio, all files inside the given directory will be an
#     individual track. The audio files must be named like Dxtory audio
#     extraction without the initial name (e.g. "st0 TRACK_NAME.flac").
#
#     The OBS recording MUST be the original file. The script grabs the "Birth"
#     timestamp from the file to determine the exact moment the recording
#     started, which may be used to generate subtitles from "chat.txt" in the
#     near future.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# Argument Check
if [ $# -ne 3 ]; then
	printf "usage: %s video_file audio_dir chat" "$0"
	exit 1
fi

# -----------------------------------------------------------------------------
# Error Checking                                                           {{{1
# -----------------------------------------------------------------------------

# Video file
if [ ! -e "$1" ]; then
	printf "fatal: \"%s\" is not a file.\n" "$1"
	exit 2
fi

# Audio file directory validity
if [ ! -d "$2" ]; then
	printf "fatal: \"%s\" is not a valid directory.\n" "$2"
	exit 3
fi

# Chat log
if [ ! -e "$1" ]; then
	printf "fatal: \"%s\" is not a file.\n" "$1"
	exit 2
fi

# -----------------------------------------------------------------------------
# Data Generation                                                          {{{1
# -----------------------------------------------------------------------------

# Generate audio track parameter data
FFMPEG_AICMD=""
FFMPEG_AMCMD=""
FFMPEG_ADCMD=""
i=0

printf "Discovering Audio Tracks...\n"

for F in "$2/st"*".flac"; do
	# Extract information
	BN=$(basename "$F")
	ID=$(echo "$BN" | sed 's/st\([0-9]\+\) .*/\1/')
	TN=$(echo "$BN" | sed 's/st[0-9]\+ \(.*\)\.\+.*/\1/')

	printf "  Track %s => %s\n" "$ID" "$TN"

	# Append to parameter strings
	FFMPEG_ADCMD="$FFMPEG_ADCMD -metadata:s:a:$i title=\"$TN\""

	let "i++"

	FFMPEG_AICMD="$FFMPEG_AICMD -i '$F'"
	FFMPEG_AMCMD="$FFMPEG_AMCMD -map $i:a"
done

printf "\nGathering timestamp metadata...\n"

# Get current time. This will be the DATE_ENCODED metadata
OIFS=$IFS
IFS=$'\n'
DATE_ENC=$(date +%Y-%m-%d\ %H:%M:%S.%N\ %z)
IFS=$OIFS

# Get video file creation time
DATE_REC=$(stat "$1" \
	| grep "Birth: " \
	| sed 's/.*: \(.*-.*-.* .*:.*:.*\..* .*\)/\1/'
)

# -----------------------------------------------------------------------------
# FFmpeg encoding                                                          {{{1
# -----------------------------------------------------------------------------

# Generate FFMPEG command
printf "\nGenerating FFMPEG command...\n"

# Start
CMD="ffmpeg -i '$1'"

# Audio includes, mapping, codecs, and metadata
CMD="$CMD $FFMPEG_AICMD -map 0:v $FFMPEG_AMCMD -c:v copy $FFMPEG_ADCMD"
CMD="$CMD -c:a flac -compression_level 12"

# Chat as attachment if possible
CMD="$CMD -attach \"$3\" -metadata:s:t:0 mimetype=\"text/plain\""

# Timestamps
CMD="$CMD -metadata DATE_ENCODED=\"$DATE_ENC\""
CMD="$CMD -metadata DATE_RECORDED=\"$DATE_REC\""

# Final export file
CMD="$CMD final.mkv"

# Show the command about to be run
#echo "$CMD"

# Unleash FFmpeg
eval "$CMD"
