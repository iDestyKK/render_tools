#!/bin/bash

# Argument Check
if [ $# -ne 1 ]; then
	printf "usage: %s dir\n" "$0"
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

# Configure FFMPEG (Audio)
ACODEC="flac"
COMPRESSION=12

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
		-map               0:v             \
		-map               0:a             \
		-c:v               $VCODEC         \
		-preset            $PRESET         \
		-crf               $CRF            \
		-pix_fmt           $PIX_FMT        \
		-c:a               $ACODEC         \
		-compression_level $COMPRESSION    \
		"$2"                               \
		-i                 "$WPATH"        \
		-r                 "$FPS"          \
		-filter_complex    "[0:v][1:v]$WM[wm]" \
		-map               "[wm]"          \
		-map               0:a             \
		-c:v               $VCODEC         \
		-preset            $PRESET         \
		-crf               $CRF            \
		-pix_fmt           $PIX_FMT        \
		-c:a               $ACODEC         \
		-compression_level $COMPRESSION    \
		"$3"

	return 0
}

# Go into directory and try to render out files
cd "$1"

render "clear.avi" "clear.raw.mkv" "clear.wm.mkv"
render "intro.avi" "intro.raw.mkv" "intro.wm.mkv"
render "mission.avi" "mission.raw.mkv" "mission.wm.mkv"
