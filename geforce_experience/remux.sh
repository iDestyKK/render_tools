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

# Can we even use WavPack?
command -v wavpack > /dev/null
WV_ABLE=$?

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
	AMP=0    # Amplification Amount
	FILT=""  # FFmpeg "filter_complex", if needed

	# The Video File is obviously the video stream
	I_STR="-i \"$F\""

	# Video Metadata
	VMD="$VMD -metadata:s:v:$VI title=\"Game Video\""
	VMD="$VMD -metadata:s:v:$VI language=\"$GV_LANG\""
	MAP="$MAP -map $FI:v"
	CMP="$CMP -c:v:$VI copy"

	let "VI++"
	let "FI++"

	#
	# If a "(16ch).raw" or "(16ch).wav" file exists. Compress it via WavPack
	# and remux into an "(16ch).mka". If WavPack isn't a valid command,
	# TrueAudio (TTA) is used instead. If this file already exists, we can skip
	# the step. The 16 channel Dolby Atmos master can then be used to generate
	# a 7.1 Surround Sound file which is more compatible with video players and
	# YouTube.
	#

	if [ -e "$BF (16ch).wv" ]; then

		# A pre-compressed WV has been delivered. Remux it.
		ffmpeg -i "$BF (16ch).wv" -map 0:a -c copy "__AUDIO_tmp_16ch.mka"

	elif [ -e "$BF (16ch).tta" ]; then

		# A pre-compressed TTA has been delivered. Remux it.
		ffmpeg -i "$BF (16ch).tta" -map 0:a -c copy "__AUDIO_tmp_16ch.mka"

	elif [ -e "$BF (16ch).raw" ]; then

		#
		# A 16 channel RAW file has been delivered. Assume 48,000hz,
		# 24 bit, 16 channels.
		#

		if [ $WV_ABLE -eq 0 ]; then
			# We can use WavPack
			wavpack \
				$PARAM_WAVPACK --raw-pcm=48000,24s,16,le "$BF (16ch).raw"

			# Remux into MKA container
			ffmpeg \
				-i "$BF (16ch).wv" \
				-map 0:a \
				-c copy \
				"__AUDIO_tmp_16ch.mka"

			# Clean up
			rm -f "$BF (16ch).wv"
		else
			# We can't use WavPack. Instead, use TrueAudio (TTA) via FFmpeg
			ffmpeg \
				-f s24le -ar 48000 -ac 16 \
				-i "$BF (16ch).raw" \
				-map 0:a \
				-c tta \
				"__AUDIO_tmp_16ch.mka"
		fi

	elif [ -e "$BF (16ch).wav" ]; then

		# A 16 channel WAV file has been delivered instead.
		if [ $WV_ABLE -eq 0 ]; then
			# We can use WavPack
			wavpack $PARAM_WAVPACK "$BF (16ch).wav"

			# Remux into MKA container
			ffmpeg \
				-i "$BF (16ch).wv" \
				-map 0:a \
				-c copy \
				"__AUDIO_tmp_16ch.mka"

			# Clean up
			rm -f "$BF (16ch).wv"
		else
			# We can't use WavPack. Instead, use TrueAudio (TTA) via FFmpeg
			ffmpeg \
				-i "$BF (16ch).wav" \
				-map 0:a \
				-c tta \
				"__AUDIO_tmp_16ch.mka"
		fi

	fi

	#
	# Check if a "__AUDIO_tmp_16ch.mka" has been created fropm the disaster
	# above. If so, generate a 7.1 Surround Sound track from it.
	#

	if [ -e "__AUDIO_tmp_16ch.mka" ]; then
		#
		# A 16 channel (7.1.4.4) audio track was provided. Ensure that the
		# first track is a 7.1 track via generating it from the 16 channel
		# audio. A 7.1 mix can be generated via "flattening" the original mix
		# into 8 channels via:
		#
		#     FL  = FL + (TFL / 2) + (BFL / 2)
		#     FR  = FR + (TFR / 2) + (BFR / 2)
		#     FC  = FC + (TFL / 4) + (TFR / 4) + (BFL / 4) + (BFR / 4)
		#     LFE = LFE
		#     BL  = BL + (TBL / 2) + (BBL / 2)
		#     BR  = BR + (TBR / 2) + (BBR / 2)
		#     SL  = SL + (TBL / 2) + (BBL / 2) + (TFL / 4) + (BFL / 4)
		#     SR  = SR + (TBR / 2) + (BBR / 2) + (TFR / 4) + (BFR / 4)
		#

		C0="c0=c0 + 0.5 * c8 + 0.5 * c12"
		C1="c1=c1 + 0.5 * c9 + 0.5 * c13"
		C2="c2=c2 + 0.25 * c8 + 0.25 * c12 + 0.25 * c9 + 0.25 * c13"
		C3="c3=c3"
		C4="c4=c4 + 0.5 * c10 + 0.5 * c14"
		C5="c5=c5 + 0.5 * c11 + 0.5 * c15"
		C6="c6=c6 + 0.5 * c10 + 0.5 * c14 + 0.25 * c8 + 0.25 * c12"
		C7="c7=c7 + 0.5 * c11 + 0.5 * c15 + 0.25 * c9 + 0.25 * c13"

		CH_MAP="$C0|$C1|$C2|$C3|$C4|$C5|$C6|$C7"

		ffmpeg \
			-i "__AUDIO_tmp_16ch.mka" \
			-filter_complex "[0:a]pan=7.1|$CH_MAP[a]" \
			-map '[a]' \
			-c:a flac \
			-compression_level 12 \
			"__AUDIO_tmp_7.1ch.flac"

		# Have FFmpeg take a look at the amplification needed to make it LOUD
		AMP=$(
			ffmpeg \
				-i "__AUDIO_tmp_7.1ch.flac" \
				-af "volumedetect" \
				-f null NUL \
				2>&1 \
				| grep "max_volume" \
				| sed 's/.*max_volume: -\?\(.*\) dB/\1/'
		)

		#
		# Since a 7.1ch and a 16ch track is guaranteed to exist, go on and add
		# the input and metadata information necessary.
		#

		# 7.1ch information
		I_STR="$I_STR -i __AUDIO_tmp_7.1ch.flac"
		FILT="-filter_complex \"[$FI:a:0]volume=${AMP}dB[amped]\""
		MAP="$MAP -map \"[amped]\""
		CMP="$CMP -c:a:$AI flac -compression_level 12"

		AMD="$AMD -metadata:s:a:$AI title=\"Game Audio [7.1 Surround]\""
		AMD="$AMD -metadata:s:a:$AI language=\"$GA_LANG\""

		let "AI++"
		let "FI++"

		# 16ch information
		I_STR="$I_STR -i __AUDIO_tmp_16ch.mka"
		MAP="$MAP -map $FI:a:0"
		CMP="$CMP -c:a:$AI copy"

		AMD="$AMD -metadata:s:a:$AI title=\"Game Audio [7.1.4.4 Master]\""
		AMD="$AMD -metadata:s:a:$AI language=\"$GA_LANG\""

		let "AI++"
		let "FI++"
	fi

	#
	# In the event that GeForce Experience drops audio while recording (which
	# happens way more than I would like), a "16ch_full" variation of "16ch"
	# will exist. Process this the same way as "16ch" but don't generate a
	# compatible 7.1ch variation. This full original copy is only for
	# preservation.
	#
	# Shameless C+P. I don't even care anymore. It's temporary.
	#

	if [ -e "$BF (16ch_full).wv" ]; then

		# A pre-compressed WV has been delivered. Remux it.
		ffmpeg -i "$BF (16ch_full).wv" -map 0:a -c copy "__AUDIO_tmp_16ch_full.mka"

	elif [ -e "$BF (16ch_full).tta" ]; then

		# A pre-compressed TTA has been delivered. Remux it.
		ffmpeg -i "$BF (16ch_full).tta" -map 0:a -c copy "__AUDIO_tmp_16ch_full.mka"

	elif [ -e "$BF (16ch_full).raw" ]; then

		#
		# A 16 channel RAW file has been delivered. Assume 48,000hz,
		# 24 bit, 16 channels.
		#

		if [ $WV_ABLE -eq 0 ]; then
			# We can use WavPack
			wavpack \
				$PARAM_WAVPACK --raw-pcm=48000,24s,16,le "$BF (16ch_full).raw"

			# Remux into MKA container
			ffmpeg \
				-i "$BF (16ch_full).wv" \
				-map 0:a \
				-c copy \
				"__AUDIO_tmp_16ch_full.mka"

			# Clean up
			rm -f "$BF (16ch_full).wv"
		else
			# We can't use WavPack. Instead, use TrueAudio (TTA) via FFmpeg
			ffmpeg \
				-f s24le -ar 48000 -ac 16 \
				-i "$BF (16ch_full).raw" \
				-map 0:a \
				-c tta \
				"__AUDIO_tmp_16ch_full.mka"
		fi

	elif [ -e "$BF (16ch_full).wav" ]; then

		# A 16 channel WAV file has been delivered instead.
		if [ $WV_ABLE -eq 0 ]; then
			# We can use WavPack
			wavpack $PARAM_WAVPACK "$BF (16ch_full).wav"

			# Remux into MKA container
			ffmpeg \
				-i "$BF (16ch_full).wv" \
				-map 0:a \
				-c copy \
				"__AUDIO_tmp_16ch_full.mka"

			# Clean up
			rm -f "$BF (16ch_full).wv"
		else
			# We can't use WavPack. Instead, use TrueAudio (TTA) via FFmpeg
			ffmpeg \
				-i "$BF (16ch_full).wav" \
				-map 0:a \
				-c tta \
				"__AUDIO_tmp_16ch_full.mka"
		fi

	fi

	if [ -e "__AUDIO_tmp_16ch_full.mka" ]; then
		# 16ch_full information
		I_STR="$I_STR -i __AUDIO_tmp_16ch_full.mka"
		MAP="$MAP -map $FI:a:0"
		CMP="$CMP -c:a:$AI copy"

		AMD="$AMD -metadata:s:a:$AI title=\"Game Audio [7.1.4.4 Master -"
		AMD="$AMD Unedited]\""

		AMD="$AMD -metadata:s:a:$AI language=\"$GA_LANG\""

		let "AI++"
		let "FI++"
	fi

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
		MAP="$MAP -map 0:a:0"
		AMD="$AMD -metadata:s:a:$AI title=\"Game Audio [GeForce Experience]\""
		AMD="$AMD -metadata:s:a:$AI language=\"$GA_LANG\""
		CMP="$CMP -c:a:$AI copy"
		let "AI++"
	#fi

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
	MD="$MD -disposition none"

	# Generate initial MKV file
	eval "ffmpeg $FFMPEG_PARAM $I_STR $FILT $MAP $CMP $VMD $AMD $MD \"$OUT\""

	# Generate JSON file
	$SCRIPTPATH/gen_json.sh "$OUT" \
		| sed 's/"amplify": 0.0/"amplify": '$AMP'/' \
		> "$PROC_DIR/info.json"

	# Get JSON modification date
	STAT_MOD=$(stat "$PROC_DIR/info.json" \
		| grep "Modify: " \
		| sed 's/.*: \(.*-.*-.*\) \(.*:.*:.*\..*\) \(.*\)\(..\)$/\1T\2\3:\4/'
	)

	mv "$OUT" "$PROC_DIR/__tmp.mkv"

	# Generate final MKV file
	ffmpeg \
		-i "$PROC_DIR/__tmp.mkv" \
		-attach "$PROC_DIR/info.json" \
		-map 0:v \
		-map 0:a \
		-c copy \
		-metadata:s:t:0 filename="info.json" \
		-metadata:s:t:0 title="MKV Information" \
		-metadata:s:t:0 mimetype="application/json" \
		-metadata:s:t:0 LAST_MODIFIED="${STAT_MOD}" \
		"$OUT"

	# Clean up
	rm -f \
		"__AUDIO_tmp_7.1ch.flac" \
		"__AUDIO_tmp_16ch.mka" \
		"__AUDIO_tmp_16ch_full.mka" \
		"$PROC_DIR/__tmp.mkv" \
		"$PROC_DIR/info.json"
done
