#!/bin/bash
#
# Render (Frames Mode)
#
# Description:
#     Same as "render.sh", but expects a "frames" directory to be inside the
#     directory to render instead of a AVI file. This is for events where
#     frame-by-frame editing in Adobe After Effects fails (which it did...) and
#     manual frame-by-frame editing needs to be done.
#
#     This script will expect frames in "frame%05.png" format, aka
#     "frame00000.png", "frame00001.png", "frame00002.png", etc.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

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

	# If frames PNG directory doesn't exist
	if [ ! -d "$1/frames" ]; then
		return 4
	fi

	# If audio track doesn't exist
	if [ ! -e "$1/recording.wav" ]; then
		return 5
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
		-i                 "$1/recording.wav"        \
		-r                 "$FPS"                    \
		-i                 "$1/frames/frame%05d.png" \
		-map               1:v                       \
		-map               0:a                       \
		-c:v               $VCODEC                   \
		-preset            $PRESET                   \
		-crf               $CRF                      \
		-pix_fmt           $PIX_FMT                  \
		-c:a               $ACODEC                   \
		-compression_level $COMPRESSION              \
		-shortest                                    \
		"$2"                                         \
		-i                 "$WPATH"                  \
		-r                 "$FPS"                    \
		-filter_complex    "[1:v][2:v]$WM[wm]"       \
		-map               "[wm]"                    \
		-map               0:a                       \
		-c:v               $VCODEC                   \
		-preset            $PRESET                   \
		-crf               $CRF                      \
		-pix_fmt           $PIX_FMT                  \
		-c:a               $ACODEC                   \
		-compression_level $COMPRESSION              \
		-shortest                                    \
		"$3"

	return 0
}

# Go into directory and try to render out files
cd "$1"

render "clear" "clear.raw.mkv" "clear.wm.mkv"
render "intro" "intro.raw.mkv" "intro.wm.mkv"
render "gameplay" "mission.raw.mkv" "mission.wm.mkv"
