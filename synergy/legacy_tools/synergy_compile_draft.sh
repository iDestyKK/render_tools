#!/bin/bash

# If you passed in no parameters, you don't know what you're doing.
if [ $# -ne 4 ]; then
	printf "Usage: %s dkk_dir skk_dir d4_dir django_dir" "$0"
	exit 0
fi

# Input files
BG='bg_draft.png'

F_DKK="$1"
F_SKK="$2"
F_D4_="$3"
F_DJ_="$4"

# Configure Delay
P1_DELAY="0.0"
P2_DELAY="2.9"
P3_DELAY="2.95"
P4_DELAY="4.15"

# And Time Limit
T_LIMIT="156.66"

# Run a list on each directory to grab the files and put it in a list file
# DKK List
cd "${F_DKK}"
ls -1 *.avi | sed -e "s/^/file '/" -e "s/$/'/" > list.txt
cd -

# SKK List
cd "${F_SKK}"
ls -1 *.avi | sed -e "s/^/file '/" -e "s/$/'/" > list.txt
cd -

# D4 List
cd "${F_D4_}"
ls -1 *.avi | sed -e "s/^/file '/" -e "s/$/'/" > list.txt
cd -

# Django List
cd "${F_DJ_}"
ls -1 *.avi | sed -e "s/^/file '/" -e "s/$/'/" > list.txt
cd -

# Begin constructing the filter_complex string
SCALEF="scale=800:-1"

# Input parameters
F_DKK_IN="[1:v]${SCALEF}[dkk]"
F_SKK_IN="[2:v]${SCALEF}[skk]"
F_D4__IN="[3:v]${SCALEF}[d4_]"
F_DJ__IN="[4:v]${SCALEF}[dj_]"

# Output parameters
F_DKK_OUT="[dkk]overlay=x=147:y=78"  # Top Left
F_SKK_OUT="[skk]overlay=x=973:y=78"  # Top Right
F_D4__OUT="[d4_]overlay=x=147:y=553" # Bottom Left
F_DJ__OUT="[dj_]overlay=x=973:y=553" # Bottom Right

# Construct the steps
S1="[0:v]${F_DKK_OUT}[v1]"
S2="[v1]${F_SKK_OUT}[v2]"
S3="[v2]${F_D4__OUT}[v3]"
S4="[v3]${F_DJ__OUT}[v4]"

# Finally construct the string
INPUT_STR="${F_DKK_IN};${F_SKK_IN};${F_D4__IN};${F_DJ__IN};"
OUTPUT_STR="${S1};${S2};${S3};${S4}"

# Watch this...
/h/Fraps/ffmpeg.exe \
	-r 60                                                           \
	-i "${BG}"                                                      \
	-itsoffset ${P1_DELAY} -f concat -safe 0 -i "${F_DKK}/list.txt" \
	-itsoffset ${P2_DELAY} -f concat -safe 0 -i "${F_SKK}/list.txt" \
	-itsoffset ${P3_DELAY} -f concat -safe 0 -i "${F_D4_}/list.txt" \
	-itsoffset ${P4_DELAY} -f concat -safe 0 -i "${F_DJ_}/list.txt" \
	-filter_complex "${INPUT_STR}${OUTPUT_STR}"                     \
	-map "[v4]"                                                     \
	-map 1:a                                                        \
	-map 2:a                                                        \
	-map 3:a                                                        \
	-map 4:a                                                        \
	-metadata:s:a:0 title="Game - DKK"                              \
	-metadata:s:a:1 title="Game - SKK"                              \
	-metadata:s:a:2 title="Game - D4"                               \
	-metadata:s:a:3 title="Game - Django"                           \
	-t "${T_LIMIT}"                                                 \
	-vcodec libx264                                                 \
	-crf 20                                                         \
	-pix_fmt yuv420p                                                \
	-acodec flac                                                    \
	test.mkv

# DEBUG: Old stuff if you want to export a raw 2 second segment
	#-vcodec rawvideo                            \
	#-pix_fmt bgr24                              \
	#-t 2                                        \
	#-acodec copy                                \
	#out.avi
