#!/bin/bash
#
# FFMPEG-powered Batch Renderer for HDR footage
#
# Description:
#     Renders AVI files in "queue" as MKV files in "processed". Any
#     already-rendered videos will be skipped. This script embeds HDR
#     information into the MKV file. You will have to tweak the values based on
#     your monitor.
#
#     No parameters needed. Just naively renders and appends multitrack audio
#     it exists the same way as "../gameplay/avi_proc.sh".
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# 1. Setup                                                                 {{{1
# -----------------------------------------------------------------------------

# Where are we?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
UTIL="${SPATH}/../util"
PR="${SPATH}/processed"

# -----------------------------------------------------------------------------
# 2. Construct HDR x265 param string                                       {{{1
# -----------------------------------------------------------------------------

# Configure Colour Primaries and Display Luminance
CPRIM_RED="R(32568,16602)"
CPRIM_BLU="B(7520,2978)"
CPRIM_GRE="G(15332,31543)"
CPRIM_WPT="WP(15674,16455)"
LUMINANCE="L(14990000,100)"
MAX_CLL=1499
MAX_FALL=799

# Ok... construct the string
X265_P="colorprim=bt2020:colormatrix=bt2020nc:transfer=smpte2084"
X265_P="${X265_P}:colormatrix=bt2020nc:hdr=1:info=1:repeat-headers=1"
X265_P="${X265_P}:max-cll=${MAX_CLL},${MAX_FALL}:master-display="
X265_P="${X265_P}${CPRIM_GRE}${CPRIM_BLU}${CPRIM_RED}${CPRIM_WPT}${LUMINANCE}"

# -----------------------------------------------------------------------------
# 3. Helper Functions                                                      {{{1
# -----------------------------------------------------------------------------

function gettime {
	OIFS=$IFS
	IFS=$'\n'
	printf $(date +%Y-%m-%d\ -\ %H:%M:%S)
	IFS=$OIFS
}

function gettime_mkv {
	OIFS=$IFS
	IFS=$'\n'
	printf $(date +%Y-%m-%d\ %H:%M:%S)
	IFS=$OIFS
}

# -----------------------------------------------------------------------------
# 4. Batch Rendering                                                       {{{1
# -----------------------------------------------------------------------------

function render {
	F="$1"
	MKV_F="${F/.avi/.mkv}"

	# Timestamps
	DATE_REC=$(stat "$F" \
		| grep "Birth: " \
		| sed 's/.*: \(.*-.*-.* .*:.*:.*\..*\) .*/\1/'
	)

	DATE_ENC=$(gettime_mkv)

	# Detect a 16 channel audio file and process accordingly if so
	SRAW="${F/.avi/ (16ch).wav}"
	if [ -e "$SRAW" ]; then
		# Generate 16-channel TTA (True Audio) track.
		ffmpeg \
			-i "$SRAW" \
			-c:a tta   \
			"${PR}/__AUDIO_tmp_16ch.tta"

		# Render with a 7.1 track generated instead. This mix is generated from
		# the 16 channels being "flattened" into 8 via:
		#     FL = c00 + c08 + c12
		#     FR = c01 + c09 + c13
		#     BL = c04 + c10 + c14
		#     BR = c05 + c11 + c15

		ffmpeg \
			-i "${F}"                                                         \
			-i "$SRAW"                                                        \
			-pix_fmt yuv420p10le                                              \
			-vf scale=out_color_matrix=bt2020:out_h_chr_pos=0:out_v_chr_pos=0,format=yuv420p10 \
			-filter_complex "[1:a]pan=7.1|c0=c0+c8+c12|c1=c1+c9+c13|c2=c2|c3=c3|c4=c4+c10+c14|c5=c5+c11+c15|c6=c6|c7=c7[a]" \
			-c:v libx265                                                      \
			-preset medium                                                    \
			-crf 16                                                           \
			-x265-params "${X265_P}"                                          \
			-c:a flac                                                         \
			-compression_level 12                                             \
			-map 0:v                                                          \
			-map "[a]"                                                        \
			-metadata:s:a:0 title="Game Audio [7.1 Surround]"                 \
			-metadata DATE_RECORDED="${DATE_REC}"                             \
			-metadata DATE_ENCODED="${DATE_ENC}"                              \
			"${PR}/__RENDER.mkv"
	else
		ffmpeg \
			-i "${F}"                                                         \
			-pix_fmt yuv420p10le                                              \
			-vf scale=out_color_matrix=bt2020:out_h_chr_pos=0:out_v_chr_pos=0,format=yuv420p10 \
			-c:v libx265                                                      \
			-preset medium                                                    \
			-crf 16                                                           \
			-x265-params "${X265_P}"                                          \
			-c:a flac                                                         \
			-compression_level 12                                             \
			-map 0:v                                                          \
			-map 0:1                                                          \
			-metadata:s:a:0 title="Game Audio"                                \
			-metadata DATE_RECORDED="${DATE_REC}"                             \
			-metadata DATE_ENCODED="${DATE_ENC}"                              \
			"${PR}/__RENDER.mkv"
	fi

	# If there are any extra audio files, convert to FLAC and process
	i=0
	j=0
	cmd=""
	map=""
	metadata=""

	# If the 16 channel one was created, add that one in the mix after 7.1 mix
	if [ -e "${PR}/__AUDIO_tmp_16ch.tta" ]; then
		printf \
			"[%s]     %s Found Additional Audio Track: %s\n" \
			"$(gettime)"                                     \
			"[${yellow}EXTRA${normal}]"                      \
			"16 Channel Master"

		cmd="${cmd} -i \"${PR}/__AUDIO_tmp_16ch.tta\""
		let "j++"
		map="${map} -map ${j}:a"
		metadata="${metadata} -metadata:s:a:${j} title=\"Game Audio [7.1.4.4 Master]\""
	fi

	while [ -e "${F/.avi/} st${i} ("*").wav" ]; do
		# Grab the title of the audio track from the ()'s
		title=$(\
			  ls "${F/.avi/} st${i} ("*").wav" \
			| sed -e 's/.*(\(.*\)).*$/\1/'
		)

		printf \
			"[%s]     %s Found Additional Audio Track: %s\n" \
			"$(gettime)"                                     \
			"[${yellow}EXTRA${normal}]"                      \
			"$title"

		# Encode to FLAC
		ffmpeg \
			-hide_banner                     \
			-v quiet                         \
			-y                               \
			-i "${F/.avi/} st${i} ("*").wav" \
			-acodec flac                     \
			-compression_level 12            \
			"${PR}/__AUDIO_tmp${i}.flac"

		cmd="${cmd} -i \"${PR}/__AUDIO_tmp${i}.flac\""
		let "i++"
		let "j++"
		map="${map} -map ${j}:a"
		metadata="${metadata} -metadata:s:a:${j} title=\"${title}\""
	done

	# Append to the original file by making a copy, then overwriting
	if [ $j -gt 0 ]; then
		printf \
			"[%s]     %s Muxing Extra Audio Tracks...\n" \
			"$(gettime)"                                 \
			"[${yellow}EXTRA${normal}]"


		# Run FFMPEG
		eval "ffmpeg -hide_banner -v quiet -stats -i \"${PR}/__RENDER.mkv\" ${cmd} -map 0:v -map 0:a ${map} ${metadata} -c copy \"${PR}/tmp.mkv\""

		# Cleanup and Overwrite
		rm -f "${PR}/__AUDIO_tmp"*".flac" "${PR}/__AUDIO_tmp_16ch.tta"
		mv \
			"${PR}/tmp.mkv" \
			"${PR}/__RENDER.mkv"
		echo ""
	fi
	mv "${PR}/__RENDER.mkv" "${PR}/${MKV_F}"
}

cd queue

for F in *.avi; do
	if [ -e "${PR}/${F/avi/mkv}" ]; then
		continue
	fi

	render "$F"
done

cd -
