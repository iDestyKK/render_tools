#!/bin/bash
#
# Synergy 2x2 Split-screen Renderer
#
# Description:
#     Encodes 4 POVs into a single 4K video. The format is defined in a way to
#     where the 4 recordings will fit in the rectangles shown in "bg_fill.png".
#     5 Audio channels will also be encoded. All 4 player POV audio separated,
#     as well as one with all of them combined.
#
#     As POV rectangles in "bg_fill.png" are 1600x900, it is suggested to
#     record your gameplays in that resolution as well. Since this is a Source
#     Engine game, it should not be an issue recording a demo and exporting it
#     at any resolution you wish.
#
#     In addition to encoding, this is also the ultimate archiving solution for
#     allowing access to the original demos in the future. As such, I'm forcing
#     the backup of demo files in the same fashion as done in "dev/gba". It'll
#     compress them all into a single TAR.XZ archive and embed it into the MKV.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Argument Checking                                                        {{{1
# -----------------------------------------------------------------------------

# If you passed in no parameters, you don't know what you're doing.
if [ $# -ne 14 ] && [ $# -ne 18 ]; then
	printf \
		"usage: %s %s %s %s %s %s [%s] %s\n"      \
			"$0"                                  \
			"p1_avi p1_delay p1_dem"              \
			"p2_avi p2_delay p2_dem"              \
			"p3_avi p3_delay p3_dem"              \
			"p4_avi p4_delay p4_dem"              \
			"duration"                            \
			"p1_audio p2_audio p3_audio p4_audio" \
			"output_mkv"
	exit 1
fi

# -----------------------------------------------------------------------------
# Setup                                                                    {{{1
# -----------------------------------------------------------------------------

# Input files
BG='bg_full.png'

F_P1="${1}"
F_P2="${4}"
F_P3="${7}"
F_P4="${10}"

# Configure Delay
P1_DELAY="${2}"
P2_DELAY="${5}"
P3_DELAY="${8}"
P4_DELAY="${11}"

# ...And their Millisecond versions
P1_DELAY_MS=$(echo $P1_DELAY | awk '{ printf "%d", $1*1000 }')
P2_DELAY_MS=$(echo $P2_DELAY | awk '{ printf "%d", $1*1000 }')
P3_DELAY_MS=$(echo $P3_DELAY | awk '{ printf "%d", $1*1000 }')
P4_DELAY_MS=$(echo $P4_DELAY | awk '{ printf "%d", $1*1000 }')

# And Time Limit
T_LIMIT="${13}"

# Begin constructing the filter_complex string
SCALEF="scale=1600:-1"

# Input parameters
F_P1_IN="[1:v]${SCALEF}[pov1]"
F_P2_IN="[2:v]${SCALEF}[pov2]"
F_P3_IN="[3:v]${SCALEF}[pov3]"
F_P4_IN="[4:v]${SCALEF}[pov4]"

# Output parameters
F_P1_OUT="[pov1]overlay=x=294:y=154"   # Top Left
F_P2_OUT="[pov2]overlay=x=1946:y=154"  # Top Right
F_P3_OUT="[pov3]overlay=x=294:y=1106"  # Bottom Left
F_P4_OUT="[pov4]overlay=x=1946:y=1106" # Bottom Right

# Construct the steps
S1="[0:v]${F_P1_OUT}[v1]"
S2="[v1]${F_P2_OUT}[v2]"
S3="[v2]${F_P3_OUT}[v3]"
S4="[v3]${F_P4_OUT}[v4]"

# Finally construct the string
INPUT_STR="${F_P1_IN};${F_P2_IN};${F_P3_IN};${F_P4_IN};"
OUTPUT_STR="${S1};${S2};${S3};${S4}"

# Setup audio delay filters
ABE="adelay=delays="
AFT=":all=1,asplit"

# Get current time. This will be the DATE_ENCODED metadata
OIFS=$IFS
IFS=$'\n'
DATE_ENC=$(date +%Y-%m-%d\ %H:%M:%S.%N\ %z)
IFS=$OIFS

# Function for getting file's last modified time. Useful for DATE_RECORDED
function get_rec_time() {
	printf "$(stat "$1" \
		| grep "Modify: " \
		| sed 's/.*: \(.*-.*-.* .*:.*:.*\..*\)/\1/'
	)"
}

# -----------------------------------------------------------------------------
# File Encoding Procedure                                                  {{{1
# -----------------------------------------------------------------------------

#
# The JSON file will store information about the recording and what was used
# to create it.
#

# Generate information document as a JSON file to embed into the MKV
{
	printf "{\n"

	# Date Encoded
	printf "\t\"date_encoded\": \"${DATE_ENC}\",\n"

	# Date Recorded (for each POV)
	printf "\t\"date_recorded\": [\n"
	printf "\t\t\"%s\",\n\t\t\"%s\",\n\t\t\"%s\",\n\t\t\"%s\"\n" \
		"$(get_rec_time "${3}")" \
		"$(get_rec_time "${6}")" \
		"$(get_rec_time "${9}")" \
		"$(get_rec_time "${12}")"
	printf "\t],\n"

	# Delays (in ms) for each POV
	printf "\t\"delay\": [ %s, %s, %s, %s ],\n" \
		$P1_DELAY $P2_DELAY $P3_DELAY $P4_DELAY

	# Demo original names
	printf "\t\"dem_fnames\": [\n"
	printf "\t\t\"%s\",\n\t\t\"%s\",\n\t\t\"%s\",\n\t\t\"%s\"\n" \
		"$(basename "${3}")" \
		"$(basename "${6}")" \
		"$(basename "${9}")" \
		"$(basename "${12}")"
	printf "\t],\n"

	# Video Duration
	printf "\t\"duration\": ${T_LIMIT},\n"

	# Video Encoding Settings
	printf "\t\"video_encoder_settings\": {\n"
	printf "\t\t\"vcodec\": \"libx265\",\n"
	printf "\t\t\"pix_fmt\": \"yuv420p10le\",\n"
	printf "\t\t\"crf\": 17\n"
	printf "\t}\n"

	printf "}\n"
} > "info.json"

#
# The Demo Archive will store the exact demo files used to record the split-
# -screen video displayed by the MKV file. This is so owners of the MKV file
# can, if they own the same game, have access to the original files and export
# them at higher resolutions or frame rates if they wish.
#

cp -p "${3}"  "p1.dem"
cp -p "${6}"  "p2.dem"
cp -p "${9}"  "p3.dem"
cp -p "${12}" "p4.dem"

tar -cf - "p1.dem" "p2.dem" "p3.dem" "p4.dem" | xz -9e -c - > "demos.tar.xz"

# Cleanup
rm "p1.dem" "p2.dem" "p3.dem" "p4.dem"

# -----------------------------------------------------------------------------
# MKV Encoding                                                             {{{1
# -----------------------------------------------------------------------------

# Based on arguments given, construct the final MKV deliverable
if [ $# -eq 14 ]; then
	# 14 arguments given. Use the audio files from the AVI source.
	ADELAY_STR=""
	ADELAY_STR="${ADELAY_STR} [1:1] ${ABE}${P1_DELAY_MS}${AFT} [D1][O1];"
	ADELAY_STR="${ADELAY_STR} [2:1] ${ABE}${P2_DELAY_MS}${AFT} [D2][O2];"
	ADELAY_STR="${ADELAY_STR} [3:1] ${ABE}${P3_DELAY_MS}${AFT} [D3][O3];"
	ADELAY_STR="${ADELAY_STR} [4:1] ${ABE}${P4_DELAY_MS}${AFT} [D4][O4];"
	ADELAY_STR="${ADELAY_STR} [D1][D2][D3][D4] amix=inputs=4 [outa]"

	# Watch this...
	ffmpeg \
		-r                 60                                        \
		-i                 "${BG}"                                   \
		-itsoffset         ${P1_DELAY} -i "${F_P1}"                  \
		-itsoffset         ${P2_DELAY} -i "${F_P2}"                  \
		-itsoffset         ${P3_DELAY} -i "${F_P3}"                  \
		-itsoffset         ${P4_DELAY} -i "${F_P4}"                  \
		-attach            "demos.tar.xz"                            \
		-attach            "info.json"                               \
		-filter_complex    "${INPUT_STR}${OUTPUT_STR};${ADELAY_STR}" \
		-map               "[v4]"                                    \
		-map               "[outa]"                                  \
		-map               "[O1]"                                    \
		-map               "[O2]"                                    \
		-map               "[O3]"                                    \
		-map               "[O4]"                                    \
		-metadata:s:a:0    title="Game Audio - All"                  \
		-metadata:s:a:1    title="Game Audio - DKK"                  \
		-metadata:s:a:2    title="Game Audio - SKK"                  \
		-metadata:s:a:3    title="Game Audio - D4"                   \
		-metadata:s:a:4    title="Game Audio - Django"               \
		-metadata:s:t:0    mimetype="application/x-gtar"             \
		-metadata:s:t:1    mimetype="application/json"               \
		-metadata          DATE_ENCODED="${DATE_ENC}"                \
		-t                 "${T_LIMIT}"                              \
		-c:v               libx265                                   \
		-crf               17                                        \
		-pix_fmt           yuv420p10le                               \
		-c:a               flac                                      \
		-compression_level 12                                        \
		"${14}"
else
	# 18 arguments given. Manual audio files have been given.
	ADELAY_STR=""
	ADELAY_STR="${ADELAY_STR} [5:0] ${ABE}${P1_DELAY_MS}${AFT} [D1][O1];"
	ADELAY_STR="${ADELAY_STR} [6:0] ${ABE}${P2_DELAY_MS}${AFT} [D2][O2];"
	ADELAY_STR="${ADELAY_STR} [7:0] ${ABE}${P3_DELAY_MS}${AFT} [D3][O3];"
	ADELAY_STR="${ADELAY_STR} [8:0] ${ABE}${P4_DELAY_MS}${AFT} [D4][O4];"
	ADELAY_STR="${ADELAY_STR} [D1][D2][D3][D4] amix=inputs=4 [outa]"

	# Watch this...
	ffmpeg \
		-r                 60                                        \
		-i                 "${BG}"                                   \
		-itsoffset         ${P1_DELAY} -i "${F_P1}"                  \
		-itsoffset         ${P2_DELAY} -i "${F_P2}"                  \
		-itsoffset         ${P3_DELAY} -i "${F_P3}"                  \
		-itsoffset         ${P4_DELAY} -i "${F_P4}"                  \
		-i                 "${14}"                                   \
		-i                 "${15}"                                   \
		-i                 "${16}"                                   \
		-i                 "${17}"                                   \
		-attach            "demos.tar.xz"                            \
		-attach            "info.json"                               \
		-filter_complex    "${INPUT_STR}${OUTPUT_STR};${ADELAY_STR}" \
		-map               "[v4]"                                    \
		-map               "[outa]"                                  \
		-map               "[O1]"                                    \
		-map               "[O2]"                                    \
		-map               "[O3]"                                    \
		-map               "[O4]"                                    \
		-metadata:s:a:0    title="Game Audio - All"                  \
		-metadata:s:a:1    title="Game Audio - DKK"                  \
		-metadata:s:a:2    title="Game Audio - SKK"                  \
		-metadata:s:a:3    title="Game Audio - D4"                   \
		-metadata:s:a:4    title="Game Audio - Django"               \
		-metadata:s:t:0    mimetype="application/x-gtar"             \
		-metadata:s:t:1    mimetype="application/json"               \
		-metadata          DATE_ENCODED="${DATE_ENC}"                \
		-t                 "${T_LIMIT}"                              \
		-c:v               libx265                                   \
		-crf               17                                        \
		-pix_fmt           yuv420p10le                               \
		-c:a               flac                                      \
		-compression_level 12                                        \
		"${18}"
fi

# -----------------------------------------------------------------------------
# Cleanup                                                                  {{{1
# -----------------------------------------------------------------------------

rm "info.json" "demos.tar.xz"
