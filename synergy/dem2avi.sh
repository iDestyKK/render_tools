#!/bin/bash
#
# dem2avi
#
# Description:
#     Takes a given DEM file and runs it in a Source Engine game. Utilises the
#     built in console commands to load up the DEM file, export every frame to
#     TGA, as well as sound being exported to stereo WAV. Then, the files
#     exported are used to generate a final raw AVI file.
#
#     When specifying "dem_path", it is relative to the game's "mod_dir", just
#     like what Source Engine demands.
#
#     Just a heads up, in case it wasn't already obvious, we're dealing with
#     raw files here. You will need a shitload of space. At least 1 TB free
#     should suffice for most cases.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Initialise                                                               {{{1
# -----------------------------------------------------------------------------

# Argument Check
if [ $# -ne 4 ]; then
	printf "usage: %s game_exe mod_dir dem_path out_avi\n" "$0"
	exit 1
fi

# Where are we...?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")

# Generate movie path
TMP_DIR="${SPATH}/_tmp"

if [ -d "$TMP_DIR" ]; then
	rm -rf "$TMP_DIR"
fi

mkdir "$TMP_DIR"

MOV_PATH=$(\
	echo "$TMP_DIR" \
	| sed 's/^\/\([^\/]*\)\//\U\1\E:\//' \
	| sed 's/\//\\/g'\
)

# -----------------------------------------------------------------------------
# Source Engine CFG Generate                                               {{{1
# -----------------------------------------------------------------------------

# Export a configuration file to the game's mod_dir with commands
echo "//Generated by dem2avi. Do not modify." \
	> "$2/cfg/__dem2avi.cfg"

echo ""                                >> "$2/cfg/__dem2avi.cfg"
echo "//Enable Cheats"                 >> "$2/cfg/__dem2avi.cfg"
echo "sv_cheats 1"                     >> "$2/cfg/__dem2avi.cfg"
echo ""                                >> "$2/cfg/__dem2avi.cfg"
echo "//Graphic Configuration"         >> "$2/cfg/__dem2avi.cfg"
echo "mat_fastspecular 0"              >> "$2/cfg/__dem2avi.cfg"
echo "r_waterforcereflectentities 1"   >> "$2/cfg/__dem2avi.cfg"
echo "cl_interp 0.015"                 >> "$2/cfg/__dem2avi.cfg"
echo "cl_interp_ratio 1"               >> "$2/cfg/__dem2avi.cfg"
echo "mat_picmip -10"                  >> "$2/cfg/__dem2avi.cfg"
echo "host_framerate 60"               >> "$2/cfg/__dem2avi.cfg"
echo ""                                >> "$2/cfg/__dem2avi.cfg"
echo "//Start Demo Playback"           >> "$2/cfg/__dem2avi.cfg"
echo "demo_quitafterplayback 1"        >> "$2/cfg/__dem2avi.cfg"
echo "startmovie \"$MOV_PATH\\frame\"" >> "$2/cfg/__dem2avi.cfg"
echo "playdemo \"$3\""                 >> "$2/cfg/__dem2avi.cfg"

# -----------------------------------------------------------------------------
# Run Game                                                                 {{{1
# -----------------------------------------------------------------------------

# Run... duh
"$1" -game "$(basename "$2")" -novid +exec "__dem2avi.cfg"

# Cleanup the cfg file
rm "$2/cfg/__dem2avi.cfg"

# -----------------------------------------------------------------------------
# Generate the AVI file                                                    {{{1
# -----------------------------------------------------------------------------

ffmpeg \
	-r 60                         \
	-i "${TMP_DIR}/frame%04d.tga" \
	-i "${TMP_DIR}/frame.wav"     \
	-r 60                         \
	-c:v rawvideo                 \
	-c:a copy                     \
	"$4"

exit 0
STATUS=$?

if [ $STATUS -eq 0 ]; then
	if [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR"
	fi
fi
