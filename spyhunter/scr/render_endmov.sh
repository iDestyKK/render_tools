#!/bin/bash

# Argument Check
if [ $# -ne 1 ]; then
	printf "usage: %s dir\n"
	exit 1
fi

if [ ! -d "$1" ]; then
	printf "fatal: %s doesn't exist.\n" "$1"
	exit 2
fi

# Get script path and watermark path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
WPATH="${SCRIPTPATH}/img/watermark.png"

# Configure FFMPEG (Video)
FPS="59.94"
VCODEC="libx265"
PRESET="medium"
CRF=17
PIX_FMT="yuv420p10le"
FILT="[0:v]scale=3840x2880,crop=3840:2160:0:360,setsar=1[OUTVID]"

# Configure FFMPEG (Audio)
ACODEC="flac"
COMPRESSION=12
AUDIO_FILTER="volume=-4.437dB"

# Configure Watermark Filter
WM="overlay=format=rgb,format=${PIX_FMT}"

# Render function
function render {
	# Check if file doesn't exist
	if [ ! -e "$1" ]; then
		return 1
	fi

	# Check if raw target file exists
	if [ -e "$2" ]; then
		return 2
	fi

	# Check if watermark'd target file exists
	if [ -e "$3" ]; then
		return 3
	fi

	# Output the raw and watermark'd versions
	ffmpeg \
		-i                 "$1"            \
		-r                 "$FPS"          \
		-filter_complex    "${FILT}"       \
		-map               "[OUTVID]"      \
		-map               0:a             \
		-c:v               $VCODEC         \
		-preset            $PRESET         \
		-crf               $CRF            \
		-pix_fmt           $PIX_FMT        \
		-c:a               $ACODEC         \
		-compression_level $COMPRESSION    \
		-sample_fmt        s16             \
		-af                $AUDIO_FILTER   \
		"$2"                               \
		-i                 "$WPATH"        \
		-r                 "$FPS"          \
		-filter_complex    "${FILT};[OUTVID][1:v]$WM[wm]" \
		-map               "[wm]"          \
		-map               0:a             \
		-c:v               $VCODEC         \
		-preset            $PRESET         \
		-crf               $CRF            \
		-pix_fmt           $PIX_FMT        \
		-c:a               $ACODEC         \
		-compression_level $COMPRESSION    \
		-sample_fmt        s16             \
		-af                $AUDIO_FILTER   \
		"$3"

	return 0
}

# Go into directory and try to render out files
cd "$1"

render "end_mov.mkv" "end_mov.raw.mkv" "end_mov.wm.mkv"
