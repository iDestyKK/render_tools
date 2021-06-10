#!/bin/bash
#
# MKV File Attachment Patcher
#
# Description:
#     MKV supports file attachments. Along with video streams, there can be
#     some extra data to attach post-encoding:
#
#       1. File Size/Stream JSON    (video.json        -> info.json)
#       2. Match Info               (video.match.json  -> match.json)
#       3. Events Info              (video.events.json -> events.json)
#       4. Keyboard Input Recording (video.inp         -> kb.inp)
#       5. Subtitles (Audacity TXT) (video.txt.tar.xz  -> subtitles_txt.tar.xz)
#
#     These extra files assume "video" is the filename of the MKV file without
#     the extension. The data files are stored in "data". Not all videos will
#     have all of these. In fact, most won't have more than the 3 JSON files.
#     The files that do exist will be attached to a new MKV file in "new/". If
#     attachments already exist in the MKV file, they will not be attached
#     again.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Checks                                                                   {{{1
# -----------------------------------------------------------------------------

# Argument check
if [ $# -ne 1 ]; then
	printf "usage: %s mkv_in\n" "$0"
	exit 1
fi

# Make sure that the original video exists
if [ ! -e "$1" ]; then
	printf "fatal: \"%s\" doesn't exist.\n" "$1"
	exit 2
fi

# Make sure "data" exists and is a directory
if [ ! -d "data" ]; then
	if [ -e "data" ]; then
		printf "fatal: \"data\" exists and isn't a directory. Aborting.\n"
		exit 3
	else
		printf "check: Directory \"data\" doesn't exist. Creating..."
		mkdir "data"
		printf " done.\n"
	fi
fi

# Make sure "new" exists and is a directory
if [ ! -d "new" ]; then
	if [ -e "new" ]; then
		printf "fatal: \"new\" exists and isn't a directory. Aborting.\n"
		exit 4
	else
		printf "check: Directory \"new\" doesn't exist. Creating..."
		mkdir "new"
		printf " done.\n"
	fi
fi

# -----------------------------------------------------------------------------
# Setup                                                                    {{{1
# -----------------------------------------------------------------------------

# What are we looking for?
FPATH="$1"
STEM="${FPATH/.mkv/}"

FILE_INFO="data/$STEM.json"
FILE_MATCH="data/$STEM.match.json"
FILE_EVENT="data/$STEM.events.json"
FILE_KBINP="data/$STEM.inp"
FILE_SRTRA="data/$STEM.txt.tar.xz"

# FFmpeg parameter information
FFMPEG_CMD="ffmpeg"
FFMPEG_INP="-i \"$FPATH\""
FFMPEG_MAP="-map 0:v -map 0:a -map 0:s? -map 0:t?"
FFMPEG_ADD="-c copy"
FFMPEG_MET=""
FFMPEG_OUT="\"new/$(basename "$FPATH")\""

# Start Attachment Counter at number of attachments in the file
ffmpeg -i "$FPATH" 2> __TMP_OUT.txt
TI=$(grep "Stream.*Attachment:" "__TMP_OUT.txt" | wc -l)
TOTAL=0

# -----------------------------------------------------------------------------
# Processing                                                               {{{1
# -----------------------------------------------------------------------------

# inject_file_if_possible(path, fname, title, mimetype)
function inject_file_if_possible {
	# Check if file has already been attached before
	grep "$2" "__TMP_OUT.txt" > /dev/null 2> /dev/null
	local CHK=$?

	# Inject file if it exists & if not already in MKV
	if [ -e "$1" ] && [ $CHK -eq 1 ]; then
		# Grab timestamp
		local LM=$(stat "$1" \
		  | grep "Modify: " \
		  | sed 's/.*: \(.*-.*-.*\) \(.*:.*:.*\..*\) \(.*\)\(..\)$/\1T\2\3:\4/'
		)

		FFMPEG_INP="$FFMPEG_INP -attach \"$1\""
		FFMPEG_MET="$FFMPEG_MET -metadata:s:t:$TI filename=\"$2\""
		FFMPEG_MET="$FFMPEG_MET -metadata:s:t:$TI title=\"$3\""
		FFMPEG_MET="$FFMPEG_MET -metadata:s:t:$TI mimetype=\"$4\""
		FFMPEG_MET="$FFMPEG_MET -metadata:s:t:$TI LAST_MODIFIED=\"$LM\""
		let "TI++"
		let "TOTAL++"
	fi
}

inject_file_if_possible \
	"$FILE_INFO"                      \
	"info.json"                       \
	"MKV Information"                 \
	"application/json"

inject_file_if_possible \
	"$FILE_MATCH"                     \
	"match.json"                      \
	"Match Data"                      \
	"application/json"

inject_file_if_possible \
	"$FILE_EVENT"                     \
	"events.json"                     \
	"Event Data"                      \
	"application/json"

inject_file_if_possible \
	"$FILE_KBINP"                     \
	"kb.inp"                          \
	"Keyboard Input Recording"        \
	"application/octet-stream"

inject_file_if_possible \
	"$FILE_SRTRA"                     \
	"subtitle_txt.tar.xz"             \
	"Subtitle Raws (Audacity Labels)" \
	"application/x-gtar"

# -----------------------------------------------------------------------------
# Command Execution                                                        {{{1
# -----------------------------------------------------------------------------

rm "__TMP_OUT.txt"

if [ $TOTAL -eq 0 ]; then
	exit 0
fi

eval "$FFMPEG_CMD $FFMPEG_INP $FFMPEG_MAP $FFMPEG_ADD $FFMPEG_MET $FFMPEG_OUT"
