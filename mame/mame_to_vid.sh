#!/bin/bash

# Argument check
if [ $# -ne 1 ]; then
	printf "usage: %s master.tar.xz" "$0"
	exit 1
fi

# Directory setup
MAME_DIR="~/.mame"
INP_DIR="${MAME_DIR}/inp"
SNAP_DIR="${MAME_DIR}/snap"

FILE="$1"
OUT="${FILE/tar.xz/mkv}"

# Extract 2 specific files
tar -xJf "$1" "inputs.inp" "info.json"

# Extract Metadata
ROM="$(grep "rom\":" "info.json" | sed 's/.*rom": "\(.*\)",$/\1/')"
DATE_REC="$(grep "\"MAME\": " "info.json" | sed 's/.*: "\(.*\)",/\1/')"

# Move replay over
mv inputs.inp "$INP_DIR/__tmp.inp"

# Run MAME
cd "$MAME_DIR"
mame "$ROM" -playback "__tmp.inp" -exit_after_playback -aviwrite __tmp
rm "$INP_DIR/__inp.inp"

# Go back
cd -
rm "info.json"

DATE_ENC="$(date -In | sed 's/,/./')"

# Compress
FILTER="[0:v]scale=-2:2160:flags=neighbor[out]"

ffmpeg \
	-i "$SNAP_DIR/__tmp.avi"  \
	-filter_complex         "$FILTER"     \
	-map                    '[out]'       \
	-map                    0:a           \
	-c:v                    libx265       \
	-pix_fmt                yuv420p10le   \
	-c:a                    flac          \
	-compression_level      12            \
	-metadata DATE_RECORDED="${DATE_REC}" \
	-metadata DATE_ENCODED="${DATE_ENC}" \
	"$OUT"

# Clean up
rm "$SNAP_DIR/__tmp.avi"
