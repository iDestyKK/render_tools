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

# Ok... construct the string
X265_P="colorprim=bt2020:colormatrix=bt2020nc:transfer=smpte2084"
X265_P="${X265_P}:colormatrix=bt2020nc:hdr=1:info=1:repeat-headers=1"
X265_P="${X265_P}:max-cll=0,0:master-display="
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

	ffmpeg \
		-i "${F}"                                                             \
		-pix_fmt yuv420p10le                                                  \
		-vf scale=out_color_matrix=bt2020:out_h_chr_pos=0:out_v_chr_pos=0,format=yuv420p10 \
		-c:v libx265                                                          \
		-preset medium                                                        \
		-crf 16                                                               \
		-x265-params "${X265_P}"                                              \
		-c:a flac                                                             \
		-map 0:v                                                              \
		-map 0:1                                                              \
		-metadata:s:a:0 title="Game Audio"                                    \
		-metadata DATE_RECORDED="${DATE_REC}"                                 \
		-metadata DATE_ENCODED="${DATE_ENC}"                                  \
		"${PR}/__RENDER.mkv"

	# If there are any extra audio files, convert to FLAC and process
	i=0
	cmd=""
	map=""
	metadata=""

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
		map="${map} -map ${i}:a"
		metadata="${metadata} -metadata:s:a:${i} title=\"${title}\""
	done

	# Append to the original file by making a copy, then overwriting
	if [ $i -gt 0 ]; then
		printf \
			"[%s]     %s Muxing Extra Audio Tracks...\n" \
			"$(gettime)"                                 \
			"[${yellow}EXTRA${normal}]"


		# Run FFMPEG
		eval "ffmpeg -hide_banner -v quiet -stats -i \"${PR}/__RENDER.mkv\" ${cmd} -map 0:v -map 0:a ${map} ${metadata} -c copy \"${PR}/tmp.mkv\""

		# Cleanup and Overwrite
		rm "${PR}/__AUDIO_tmp"*".flac"
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
