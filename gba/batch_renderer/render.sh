#!/bin/bash
#
# GBA Rendering Script
#
# Description:
#     All-in-One GBA script for having ffmpeg concatentate AVI segments into
#     an MKV file.
#
# Valid Parameters:
#     ahv
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

# Parameters
VCODEC="libx265"
ACODEC="flac"
CRF=17
PRESET=slow
ARCHIVE=0
PIX_FMT="yuv420p10le"
VERBOSE=0

# Where are we?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
UTIL="${SPATH}/../../util"
PR="${SPATH}/processed"
TR="${SPATH}/tmp"

# Check FFMPEG.
ffmpeg=""

if [ -x "$(command -v ffmpeg)" ]; then
	# If there is a command for "ffmpeg", use that
	ffmpeg="ffmpeg"
elif [ -e "${UTIL}/ffmpeg.exe" ]; then
	# For Windows Users, if they put a "ffmpeg.exe" in "util", it can be used.
	# For other OS's, you can try this as well to bypass the "ffmpeg" command.
	ffmpeg="${UTIL}/ffmpeg.exe"
fi

# Helper script to check if a file exists
function __chk {
	if [ $VERBOSE -eq 1 ]; then
		printf "[${yellow}CHECK${normal}] %-40s " "Checking for \"$1\"..."
	fi

	if [ ! -e "$1" ]; then
		if [ $VERBOSE -eq 1 ]; then
			printf "[${red}FAILED${normal}]\n"
		fi

		printf "[${red}FATAL${normal}] \"%s\" doesn't exist.\n" "$1" 1>&2
		exit 1
	else
		if [ $VERBOSE -eq 1 ]; then
			printf "[  ${green}OK${normal}  ]\n"
		fi
	fi
}

# Show title
function show_head {
	printf \
		"%s\n%s\n" \
		"Batch FFMPEG Renderer for GBA footage by iDestyKK" \
		"Version 2.0.0 (Last Updated: 2020/05/20)"
}

# Show Help
function show_help {
	printf "Usage: %s [-ahv]\n\n" "$0"

	# About
	show_head

	# Description
	printf \
		"\n%s %s\n%s %s\n%s\n" \
		"An automated method of encoding videos so you don't have to do" \
		"anything but" \
		"just play. Encodes AVI videos in the \"queue\" directory as MKV" \
		"files in the" \
		"\"processed\" directory."

	# Parameters
	printf "\nParameters:\n"
	printf "  %-4s %s\n" \
		"-a" "Archive the raw video directory (via tar.xz) and embed in MKV"
	printf "  %-4s %s\n" \
		"-v" "Verbose (Show more info)"
	printf "  %-4s %s\n" \
		"-h" "Show Help (and terminate the script)"
}

# -----------------------------------------------------------------------------
# 2. Parameter Reading                                                     {{{1
# -----------------------------------------------------------------------------

if [ $# -eq 1 ]; then
	for i in $(seq 1 ${#1}); do
		case "${1:i-1:1}" in
			\-)
				# Ignore "-" character (Makes it optional too)
				;;

			a)
				# Archive
				ARCHIVE=1
				;;

			h)
				# Show Help (and kill script)
				show_help
				exit 0
				;;

			v)
				# Verbose (show more info)
				VERBOSE=1
				;;

			*)
				# Invalid Option
				echo "[${yellow}WARNING${normal}] Invalid Command: ${1:i-1:1}"
				;;
		esac
	done
fi

show_head

# -----------------------------------------------------------------------------
# 3. Checking                                                              {{{1
# -----------------------------------------------------------------------------

# Check for existence of everything
if [ $VERBOSE -eq 1 ]; then
	printf "\nChecking...\n"
fi

# FFMPEG
if [ "$ffmpeg" == "" ]; then
	printf "[${red}FATAL${normal}] \"%s\" could not be found...\n" "$1" 1>&2
	exit 1
fi

# Others
__chk "queue"
__chk "processed"
__chk "tmp"

# -----------------------------------------------------------------------------
# 4. Batch Rendering                                                       {{{1
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

printf "\n"

# Go into "queue" and let's see what we can find...
cd "queue"

for D in *; do
	# If this isn't a directory, forget it.
	if [ ! -d "$D" ]; then
		continue;
	fi

	# If this directory has a rendered video already, skip the render job.
	if [ -e "${PR}/${D}.mkv" ]; then
		continue;
	fi

	# Commence...
	cd "$D"

	printf \
		"[%s] Processing %s...\n" \
		"$(gettime)" \
		"$D"

	# Archive the directory if "-a" was supplied
	if [ $ARCHIVE -eq 1 ]; then
		printf \
			"[%s]     [${green} ARC ${normal}] %s" \
			"$(gettime)" \
			"Generating master archive via tar+xz..."

		tar -cf - * | xz -9e -c - > "${TR}/master.tar.xz"

		printf "Done\n"
	fi

	#
	# Determine the mode we need to render videos by if directories exist. If a
	# directory exists, it's assumed that the there's multiple segments that
	# will be encoded into a single video. Otherwise, assume that the current
	# directory has all of the AVI files and WAV audio to encode.
	#
	# Either way, we're going to cheat with ffmpeg's concat method...
	#

	ls ./*/ >/dev/null 2>&1
	CHK=$?

	if [ $CHK -eq 0 ]; then
		# Nested directory structure discovered. Segment concatentation mode.
		v=$(find . -maxdepth 2 -name '*.avi' | sort)
		a=$(find . -maxdepth 2 -name '*.wav' | sort)

		# For audio, we need to make sure only a single audio file was added in
		# each directory.
		for DD in *; do
			if [ ! -d "$DD" ]; then
				continue;
			fi

			WAV_NUM=$(ls -1 $DD/*.wav | wc -l)

			if [ $WAV_NUM -gt 1 ]; then
				printf \
					"[%s]     [${red}ERROR${normal}] %s \"%s\"..." \
					"$(gettime)" \
					"More than 1 WAV file detected in" \
					"$D/$DD"

				exit 2
			elif [ $WAV_NUM -eq 0 ]; then
				printf \
					"[%s]     [${red}ERROR${normal}] %s \"%s\"..." \
					"$(gettime)" \
					"No WAV file detected in" \
					"$D/$DD"

				exit 3
			fi
		done
	else
		# Single directory. No segmentations here.
		v=$(find . -maxdepth 1 -name '*.avi' | sort)
		a=$(find . -maxdepth 1 -name '*.wav' | sort)

		# For audio, ditto is applied here as above. Except we need exactly one
		# WAV file... period...
		WAV_NUM=$(echo "$a" | wc -l)

		if [ $WAV_NUM -gt 1 ]; then
			printf \
				"[%s]     [${red}ERROR${normal}] %s \"%s\"..." \
				"$(gettime)" \
				"More than 1 WAV file detected in" \
				"$D"

			exit 2
		elif [ "$a" == "" ]; then
			printf \
				"[%s]     [${red}ERROR${normal}] %s \"%s\"..." \
				"$(gettime)" \
				"No WAV file detected in" \
				"$D"

			exit 3
		fi
	fi

	# Generate the files lol
	echo "$v" \
		| sed "s/^\(.*\)/file \'\1\'/" \
		| sed "s/^file '.\//file \'/"  \
		> "concat_video.txt"

	echo "$a" \
		| sed "s/^\(.*\)/file \'\1\'/" \
		| sed "s/^file '.\//file \'/"  \
		> "concat_audio.txt"

	printf \
		"[%s]     %s Rendering via ffmpeg (%s [CRF %s] w/ %s):\n" \
		"$(gettime)"                                              \
		"[${green}VIDEO${normal}]"                                \
		"$VCODEC"                                                 \
		"$CRF"                                                    \
		"$ACODEC"

	# Generate DATE_ENCODED tag
	DATE_ENC=$(gettime_mkv)

	# Render away
	if [ $ARCHIVE -eq 1 ]; then
		${ffmpeg} \
			-hide_banner                                     \
			-v                 quiet                         \
			-stats                                           \
			-safe 0                                          \
			-f concat -i       "concat_video.txt"            \
			-f concat -i       "concat_audio.txt"            \
			-attach            "${TR}/master.tar.xz"         \
			-map               0:v                           \
			-map               1:a                           \
			-c:v               ${VCODEC}                     \
			-pix_fmt           ${PIX_FMT}                    \
			-preset            ${PRESET}                     \
			-crf               ${CRF}                        \
			-x265-params       log-level=error               \
			-c:a               ${ACODEC}                     \
			-compression_level 12                            \
			-s                 1620x1080                     \
			-sws_flags         neighbor                      \
			-metadata:s:a:0    title="Game Audio"            \
			-metadata          DATE_ENCODED="${DATE_ENC}"    \
			-metadata:s:t:0    mimetype="application/x-gtar" \
			"${PR}/${D}.mkv"

		# Clean up the master archive...
		rm -f "${TR}/master.tar.xz"
	else
		${ffmpeg} \
			-hide_banner                                     \
			-v                 quiet                         \
			-stats                                           \
			-safe 0                                          \
			-f concat -i       "concat_video.txt"            \
			-f concat -i       "concat_audio.txt"            \
			-map               0:v                           \
			-map               1:a                           \
			-c:v               ${VCODEC}                     \
			-pix_fmt           ${PIX_FMT}                    \
			-preset            ${PRESET}                     \
			-crf               ${CRF}                        \
			-x265-params       log-level=error               \
			-c:a               ${ACODEC}                     \
			-compression_level 12                            \
			-s                 1620x1080                     \
			-sws_flags         neighbor                      \
			-metadata:s:a:0    title="Game Audio"            \
			-metadata          DATE_ENCODED="${DATE_ENC}"    \
			"${PR}/${D}.mkv"
	fi

	printf \
		"[%s]     [${green}NOTIC${normal}] Render Job Done!\n\n\n" \
		"$(gettime)"

	# Clean up other temporary files
	rm -f "concat_video.txt" "concat_audio.txt"

	cd .. > /dev/null 2> /dev/null
done
