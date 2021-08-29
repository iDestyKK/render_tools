#!/bin/bash
#
# FFmpeg-powered Batch Remuxer for GeForce Experience footage
#
# Description:
#     Remuxer for GeForce Experience footage to put in accurate timestamps,
#     multiple audio tracks (Dxtory-styled), metadata, and more. No parameters
#     are required. It'll naïvely go through and append everything, skipping
#     already processed videos.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Program Configuration                                                    {{{1
# -----------------------------------------------------------------------------

# Language Metadata
GV_LANG="jpn" # Game Video Language
GA_LANG="jpn" # Game Audio Language
VC_LANG="eng" # Voice Chat Language

# FFmpeg Parameters
PARAM_FFMPEG=""

# WavPack Parameters
PARAM_WAVPACK="-hhx4m"

# -----------------------------------------------------------------------------
# Script Variable Setup                                                    {{{1
# -----------------------------------------------------------------------------

# Get Script Path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Gather directory information
QUEUE_DIR="$SCRIPTPATH/queue"
PROC_DIR="$SCRIPTPATH/processed"

# -----------------------------------------------------------------------------
# Video Processing Procedure                                               {{{1
# -----------------------------------------------------------------------------

# Go into the queue directory
cd "$QUEUE_DIR"

for F in *.mp4; do
	# Base filename
	BF="${F/.mp4/}"

	# Final output file
	OUT="$PROC_DIR/$BF.mkv"

	# If the file has already been processed, skip.
	if [ -e "$OUT" ]; then
		continue
	fi

	# Generate FFmpeg parameters for input files
	VI=0     # Video Stream Index
	AI=0     # Audio Stream Index
	STI=0    # Dxtory-like Audio Stream ID
	FI=0     # Input File Index
	I_STR="" # Media Import Strings
	CMP=""   # Codec/Compression Information
	VMD=""   # Video Metadata
	AMD=""   # Audio Metadata
	MD=""    # Misc Metadata (unrelated to streams)
	MAP=""   # Mapping Information

	# The Video File is obviously the video stream
	I_STR="-i \"$F\""

	# Video Metadata
	VMD="$VMD -metadata:s:v:$VI title=\"Game Video\""
	VMD="$VMD -metadata:s:v:$VI language=\"$GV_LANG\""
	MAP="$MAP -map $FI:v"
	CMP="$CMP -c:v:$VI copy"

	let "VI++"

	#
	# If no "stX (Game Audio).*" exists, and if no "(16ch).raw" or "(16ch).wv"
	# exists, we have no choice but to use the file's audio track. The twist is
	# that we want the input file to be format-agnostic. Not just "aac". It can
	# be anything.
	#
	# EDIT: Fuck it. Let's make it add in the GeForce Experience audio anyways.
	#

	TMP_1=$(ls -N "$BF stX (Game Audio)."* 2> /dev/null)
	RES_1=$?

	TMP_2=$(ls -N "$BF (16ch)."* 2> /dev/null)
	RES_2=$?

	#if [ $RES_1 -ne 0 ] && [ $RES_2 -ne 0 ]; then
		MAP="$MAP -map $FI:a:0"
		AMD="$AMD -metadata:s:a:$AI title=\"Game Audio [GeForce Experience]\""
		AMD="$AMD -metadata:s:a:$AI language=\"$GA_LANG\""
		CMP="$CMP -c:a:$AI copy"
		let "AI++"
	#fi

	# We're done with the video file.
	let "FI++"

	#
	# Go through all st0, st1, st2, ..., stN files and append them as valid
	# audio tracks.
	#

	STI=0
	while true; do
		TMP=$(ls -N "$BF st$STI ("*")."* 2> /dev/null)
		RES=$?

		# File doesn't exist? We're done here.
		if [ $RES -ne 0 ]; then
			break
		fi

		# Get Track Name
		TRK_NAME="$(echo "$TMP" | sed "s/.*st$STI (\(.*\)).*/\1/")"

		# Get File Extension
		TRK_EXT="$(echo "${TMP##*.}" | tr '[:upper:]' '[:lower:]')"

		# Set as valid input file
		I_STR="$I_STR -i \"$TMP\""
		MAP="$MAP -map $FI:a:0"

		# If it's a WAV, compress to FLAC. If it's anything else, stream copy
		if [ $TRK_EXT = "wav" ]; then
			CMP="$CMP -c:a:$AI flac -compression_level 12"
		else
			CMP="$CMP -c:a:$AI copy"
		fi

		# Setup metadata
		AMD="$AMD -metadata:s:a:$AI title=\"$TRK_NAME\""
		AMD="$AMD -metadata:s:a:$AI language=\"$VC_LANG\""

		# Increment
		let "FI++"
		let "AI++"
		let "STI++"
	done

	# Get file creation timestamp
	DATE_REC=$(stat "$F" \
		| grep "Birth: " \
		| sed 's/.*: \(.*-.*-.*\) \(.*:.*:.*\..*\) \(.*\)\(..\)$/\1T\2\3:\4/'
	)

	DATE_ENC=$(date +%Y-%m-%dT%H:%M:%S.%N%:z)

	MD="$MD -metadata DATE_RECORDED=\"$DATE_REC\""
	MD="$MD -metadata DATE_ENCODED=\"$DATE_ENC\""

	eval "ffmpeg $FFMPEG_PARAM $I_STR $MAP $CMP $VMD $AMD $MD \"$OUT\""
done
