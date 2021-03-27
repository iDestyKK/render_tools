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

# Colours
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
normal=$(tput sgr 0)

# Where are we?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
UTIL="${SPATH}/../util"
PR="${SPATH}/processed"
TDIR="${SPATH}/tools/bin/$OSTYPE"

# Video Language Metadata (ISO 639-2)
GV_LANG="jpn" # Game Video Language
GA_LANG="jpn" # Game Audio Language
VC_LANG="eng" # Voice Chat Language

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
	printf $(date +%Y-%m-%dT%H:%M:%S.%N%:z)
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
		| sed 's/.*: \(.*-.*-.*\) \(.*:.*:.*\..*\) \(.*\)\(..\)$/\1T\2\3:\4/'
	)

	DATE_ENC=$(gettime_mkv)

	# Detect a 16 channel audio file and process accordingly if so
	SRAW="${F/.avi/ (16ch).tta}"
	WRAW="${F/.avi/ (16ch).wav}"

	# Handle the generation of the temporary compressed 16 channel file
	if [ -e "$SRAW" ]; then
		# Simply copy the file over. It's already compressed.
		cp "$SRAW" "${PR}/__AUDIO_tmp_16ch.tta"
	elif [ -e "$WRAW" ]; then
		# Generate 16-channel TTA (True Audio) track.
		ffmpeg \
			-i "$WRAW" \
			-c:a tta   \
			"${PR}/__AUDIO_tmp_16ch.tta"
	fi

	# Encode video
	if [ -e "${PR}/__AUDIO_tmp_16ch.tta" ]; then
		#
		# A 16 channel (7.1.4.4) audio track was provided. Ensure that the
		# first track is a 7.1 track via generating it from the 16 channel
		# audio. A 7.1 mix can be generated via "flattening" the original mix
		# into 8 channels via:
		#
		#     FL  = FL + (TFL / 2) + (BFL / 2)
		#     FR  = FR + (TFR / 2) + (BFR / 2)
		#     FC  = FC + (TFL / 4) + (TFR / 4) + (BFL / 4) + (BFR / 4)
		#     LFE = LFE
		#     BL  = BL + (TBL / 2) + (BBL / 2)
		#     BR  = BR + (TBR / 2) + (BBR / 2)
		#     SL  = SL + (TBL / 2) + (BBL / 2) + (TFL / 4) + (BFL / 4)
		#     SR  = SR + (TBR / 2) + (BBR / 2) + (TFR / 4) + (BFR / 4)
		#

		C0="c0=c0 + 0.5 * c8 + 0.5 * c12"
		C1="c1=c1 + 0.5 * c9 + 0.5 * c13"
		C2="c2=c2 + 0.25 * c8 + 0.25 * c12 + 0.25 * c9 + 0.25 * c13"
		C3="c3=c3"
		C4="c4=c4 + 0.5 * c10 + 0.5 * c14"
		C5="c5=c5 + 0.5 * c11 + 0.5 * c15"
		C6="c6=c6 + 0.5 * c10 + 0.5 * c14 + 0.25 * c8 + 0.25 * c12"
		C7="c7=c7 + 0.5 * c11 + 0.5 * c15 + 0.25 * c9 + 0.25 * c13"

		CH_MAP="$C0|$C1|$C2|$C3|$C4|$C5|$C6|$C7"

		ffmpeg \
			-i "${F}"                                                         \
			-i "${PR}/__AUDIO_tmp_16ch.tta"                                   \
			-pix_fmt yuv420p10le                                              \
			-vf scale=out_color_matrix=bt2020:out_h_chr_pos=0:out_v_chr_pos=0,format=yuv420p10 \
			-filter_complex "[1:a]pan=7.1|$CH_MAP[a]" \
			-c:v libx265                                                      \
			-preset medium                                                    \
			-crf 16                                                           \
			-x265-params "${X265_P}"                                          \
			-c:a flac                                                         \
			-compression_level 12                                             \
			-map 0:v                                                          \
			-map "[a]"                                                        \
			-metadata:s:a:0 title="Game Audio [7.1 Surround]"                 \
			-metadata:s:a:0 language="${GA_LANG}"                             \
			-metadata:s:v:0 title="Game Video"                                \
			-metadata:s:v:0 language="${GV_LANG}"                             \
			-metadata DATE_RECORDED="${DATE_REC}"                             \
			-metadata DATE_ENCODED="${DATE_ENC}"                              \
			"${PR}/__RENDER.mkv"
	else
		#
		# No 16 channel audio was provided. So just encode with whatever is in
		# the first audio track.
		#

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
			-metadata:s:a:0 language="${GA_LANG}"                             \
			-metadata:s:v:0 title="Game Video"                                \
			-metadata:s:v:0 language="${GV_LANG}"                             \
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
		metadata="${metadata} -metadata:s:a:${j} language=\"${GA_LANG}\""
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
		metadata="${metadata} -metadata:s:a:${j} language=\"${VC_LANG}\""
	done

	#
	# If there are any Audacity TXT files, convert them to SRT and process...
	# but only if txt2srt exists in the "tools/$OSTYPE/" directory.
	#

	if [ -e "${TDIR}/txt2srt" ]; then
		k=0
		l=$j
		m=0
		snum=0
		cstr=""
		ffps=""

		#
		# This is done in 2 phases. First up, combine all subtitles together.
		# The txt2srt executable supports combining multiple TXT sources into a
		# single SRT file with events properly ordered.
		#

		while [ -e "${F/.avi/} st${k} ("*").txt" ]; do
			# Grab the title of the audio track from the ()'s
			title=$(\
				  ls "${F/.avi/} st${k} ("*").txt" \
				| sed -e 's/.*(\(.*\)).*$/\1/'
			)

			printf \
				"[%s]     %s Found Subtitle Track: %s\n" \
				"$(gettime)"                                     \
				"[${yellow}EXTRA${normal}]"                      \
				"$title"

			cp "${F/.avi/} st${k} ("*").txt" "__SUBTITLE_tmp${k}.txt"
			cstr="${cstr} \"__SUBTITLE_tmp${k}.txt\""

			${TDIR}/txt2srt "__SUBTITLE_tmp${k}.txt" \
				> "${PR}/__SUBTITLE_tmp${k}.srt"

			let "k++"
			let "l++"
		done

		# Scanner finding nothing just means there aren't any subtitles... lol
		if [ $k -gt 0 ]; then
			snum=$k
			m=0

			# Only create a huge mixed SRT if more than one track exists.
			if [ $k -gt 1 ]; then
				printf \
					"[%s]     %s Mixing all %d subtitle tracks into one\n" \
					"$(gettime)"                                     \
					"[${yellow}EXTRA${normal}]"                      \
					"$snum"

				# Generate the SRT that has everything
				eval "${TDIR}/txt2srt ${cstr} > \"${PR}/__SUBTITLE_tmp_C.srt\""

				# Clean up
				rm "__SUBTITLE_tmp"*".txt"

				k=0
				l=$j
				let "l++"

				cmd="${cmd} -i \"${PR}/__SUBTITLE_tmp_C.srt\""
				map="${map} -map ${l}:s"
				metadata="${metadata} -metadata:s:s:${m} title=\"Voice - All\""
				metadata="${metadata} -metadata:s:s:${m} language=\"${VC_LANG}\""

				let "m++"
			else
				k=0
				l=$j
			fi

			# Concatenated SRT generated. Now reset and do the real deal.
			printf \
				"[%s]     %s Converted TXT files to SRT files... %s" \
				"$(gettime)"                                     \
				"[${yellow}EXTRA${normal}]"                      \
				"(0 of $snum)"

			while [ -e "${F/.avi/} st${k} ("*").txt" ]; do
				# Grab the title of the audio track from the ()'s
				title=$(\
					  ls "${F/.avi/} st${k} ("*").txt" \
					| sed -e 's/.*(\(.*\)).*$/\1/'
				)

				let "l++"

				cmd="${cmd} -i \"${PR}/__SUBTITLE_tmp${k}.srt\""
				map="${map} -map ${l}:s"
				metadata="${metadata} -metadata:s:s:${m} title=\"${title}\""
				metadata="${metadata} -metadata:s:s:${m} language=\"${VC_LANG}\""

				let "k++"
				let "m++"

				printf \
					"\r[%s]     %s Converted TXT files to SRT files... %s" \
					"$(gettime)"                                     \
					"[${yellow}EXTRA${normal}]"                      \
					"($k of $snum)"
			done

			printf "\n"

			j=$l
		fi
	fi

	# Append to the original file by making a copy, then overwriting
	if [ $j -gt 0 ]; then
		printf \
			"[%s]     %s Muxing Extra Tracks...\n" \
			"$(gettime)"                                 \
			"[${yellow}EXTRA${normal}]"


		# Run FFMPEG
		eval "ffmpeg -hide_banner -v quiet -stats -i \"${PR}/__RENDER.mkv\" ${cmd} -map 0:v -map 0:a ${map} ${metadata} -c copy \"${PR}/tmp.mkv\""

		# Cleanup
		rm -f \
			"${PR}/__AUDIO_tmp"*".flac" \
			"${PR}/__AUDIO_tmp_16ch.tta" \
			"${PR}/__SUBTITLE_tmp"*".srt"

		# Overwrite
		mv \
			"${PR}/tmp.mkv" \
			"${PR}/__RENDER.mkv"

		echo ""
	fi

	# Final Copy
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
