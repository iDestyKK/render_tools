#!/bin/bash
#
# Compile all videos
#
# Description:
#     Generates video resources into final uploadable MKV files. There are 4
#     versions that have to be accounted for:
#       - English  - RAW
#       - English  - Watermarked
#       - Japanese - RAW
#       - Japanese - Watermarked
#
#     The segments of these versions exist in "$LANG/$PART/segments" and have
#     already been pre-rendered. This script's job is just to concatenate all
#     of the resources so that "$LANG/final" will have the final MKV files for
#     upload to YouTube or the like.
#
#     These "final MKV files" will feature 5.1 and Stereo audio tracks, English
#     subtitles, and chapter metadata. Files that already exist in the "final"
#     directories will not be re-concatenated (kinda like GNU make).
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# Get script path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# -----------------------------------------------------------------------------
# Helper Functions                                                         {{{1
# -----------------------------------------------------------------------------

#
# render                                                                   {{{2
#
# C Syntax:
#     void render(root_dir, variant, output_path)
#
# Description:
#     Renders out a video from the "root_dir" (aka, where the "audio", "data"
#     "segments", and "subtitle" directories exist). It only builds one
#     variant, specified by "variant" (either "raw" or "watermark"). The final
#     video is stored in "output_path"
#
# Return Values:
#     0 - Successful
#     1 - Video already exists at "output_path"
#     2 - Other error
#

function render {
	if [ -e "$3" ]; then
		return 1
	fi

	cd "$1" > /dev/null

	# Create concatenation file
	SRC_DIR=$(printf "segments/%s" "$2")
	echo "file '${SRC_DIR}/intro.mkv'"    > __concat.txt
	echo "file '${SRC_DIR}/mission.mkv'" >> __concat.txt
	echo "file '${SRC_DIR}/end_mov.mkv'" >> __concat.txt
	echo "file '${SRC_DIR}/clear.mkv'"   >> __concat.txt

	# Commence
	ffmpeg \
		-safe              0                                 \
		-f                 concat                            \
		-i                 "__concat.txt"                    \
		-i                 "audio/5.1.flac"                  \
		-i                 "audio/stereo.flac"               \
		-i                 "subtitles/en.srt"                \
		-i                 "data/ffmetadata.txt"             \
		-map               0:v                               \
		-map               1:a                               \
		-map               2:a                               \
		-map               3:s                               \
		-c:v               copy                              \
		-c:a               flac                              \
		-c:s               copy                              \
		-compression_level 12                                \
		-metadata:s:s:0    language=eng                      \
		-metadata:s:a:0    title="Game Audio [5.1 Surround]" \
		-metadata:s:a:1    title="Game Audio [Stereo]"       \
		"$3"

	cd ".." > /dev/null

	# We're done here
	rm -f __concat.txt
	return 0
}

#
# process_lang                                                             {{{2
#
# C Syntax:
#     void process_lang(lang_dir)
#
# Description:
#     Runs compile procedure on specific language (either "English" or
#     "Japanese").
#
# Return Values:
#     0 - Successful
#     1 - Directory isn't valid (doesn't exist or not a directory)
#     2 - "final" directory isn't valid (doesn't exist or not a directory)
#

function process_lang {
	# Check if directory even exists and is valid
	if [ ! -d "$1" ]; then
		return 1
	fi

	# Check if "final" is in there and is valid
	if [ ! -d "$1/final" ]; then
		return 2
	fi

	cd "$1" > /dev/null

	# Commence
	for D in *; do
		# Skip the "final" directory. It's where final videos go.
		if [ "$D" == "final" ]; then
			continue
		fi

		# Concatenate both "raw" and "watermark" variants
		render "$D" "raw"       "$(pwd)/final/raw/${D}.mkv"
		render "$D" "watermark" "$(pwd)/final/${D}.mkv"
	done

	cd ".." > /dev/null

	# We're done here
	return 0
}

# -----------------------------------------------------------------------------
# Entry Point                                                              {{{1
# -----------------------------------------------------------------------------

# Force directory to be one before "scr" (where this script should be tbh)
cd "${SCRIPTPATH}/../"

# Scan all directories and run "process_lang" on all but "scr"
for D in *; do
	if [ "$D" == "scr" ]; then
		continue
	fi

	process_lang "$D"
	RES=$?

	# Account for error messages
	if [ $RES -eq 1 ]; then
		printf \
			"error: \"%s\" either doesn't exist or isn't valid.\n" "$D"
	elif [ $RES -eq 2 ]; then
		printf \
			"error: \"%s\" either doesn't exist or isn't valid.\n" "$D/final"
	fi
done
