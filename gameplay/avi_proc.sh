#!/bin/bash
#
# FFMPEG-powered Batch Renderer
# Version 2.0.0 (Last Updated: 2019/07/30)
#
# Description:
#     Renders all AVI videos in "queue" as MKV files into "processed". Any
#     already-rendered videos will be skipped.
#
# Parameters:
#     -a  AMPLIFY
#         Normalises the first audio track in each rendered MKV.
#
#     -4  X264 RENDERING
#         All files rendered will use x264
#
#     -5  X265 RENDERING
#         All files rendered will use x265
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
CODEC="libx265"
NORMALISE=0
PIX_FMT="yuv420p10le"
VERBOSE=0

# Where are we?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
UTIL="${SPATH}/../util"
ffmpeg="${UTIL}/ffmpeg.exe"

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
		"Batch FFMPEG Renderer for Gameplay by iDestyKK" \
		"Version 2.0.0 (Last Updated: 2019/07/30)"
}

# Show Help
function show_help {
	printf "Usage: %s [-adhv45]\n\n" "$0"

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
		"-a" "Amplify (Normalise) first audio track in AVI"
	printf "  %-4s %s\n" \
		"-d" "Disable 10-bit encoding"
	printf "  %-4s %s\n" \
		"-h" "Show Help (and terminate the script)"
	printf "  %-4s %s\n" \
		"-v" "Verbose (Show more info)"
	printf "  %-4s %s\n" \
		"-4" "x264 Encoding"
	printf "  %-4s %s\n" \
		"-5" "x265 Encoding"

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
				# Amplify (Normalise)
				NORMALISE=1
				;;

			4)
				# x264 Encoding
				CODEC="libx264"
				;;

			5)
				# x265 Encoding
				CODEC="libx265"
				;;

			d)
				# Disable 10-bit encoding
				PIX_FMT="yuv420p"
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
				echo "Invalid Command: ${1:i-1:1}"
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

__chk "${UTIL}/ffmpeg.exe"
__chk "${UTIL}/gen_json.sh"
__chk "settings.dat"
__chk "queue"
__chk "processed"
__chk "queue/regular"
__chk "queue/bluray"

# Assume the checks worked (It would've died by now otherwise)

# -----------------------------------------------------------------------------
# 4. Overview                                                              {{{1
# -----------------------------------------------------------------------------

printf "\nBATCH RENDERING CONFIGURATION:\n"

# Tell the user what the script is configured to do
printf "  %-32s   %-11s     %-11s \n" \
	"" "SETTING" "DEFAULT"

# Encoder
printf "  %-32s " "Encoder"
printf "[ ${green}%-11s${normal} ]" "ffmpeg"
printf " [ %-11s ]\n" "ffmpeg"

# Encoding Codec
printf "  %-32s " "Encoding Codec"
if [ "${CODEC}" != "libx265" ]; then
	printf "[ ${yellow}%-11s${normal} ]" "${CODEC}"
else
	printf "[ ${green}%-11s${normal} ]" "${CODEC}"
fi
printf " [ %-11s ]\n" "libx265"

# Pixel Format
printf "  %-32s " "Pixel Format"
if [ "${PIX_FMT}" != "yuv420p10le" ]; then
	printf "[ ${yellow}%-11s${normal} ]" "${PIX_FMT}"
else
	printf "[ ${green}%-11s${normal} ]" "${PIX_FMT}"
fi
printf " [ %-11s ]\n" "yuv420p10le"

# Audio Normalisation
printf "  %-32s " "Audio Normalisation"
if [ $NORMALISE != 0 ]; then
	printf "[ ${yellow}%-11s${normal} ]" "on"
else
	printf "[ ${green}%-11s${normal} ]" "off"
fi
printf " [ %-11s ]\n" "off"

# Multitrack Audio Detection
printf "  %-32s " "Multitrack Audio Detection"
printf "[ ${green}%-11s${normal} ]" "on"
printf " [ %-11s ]\n" "on"

printf "\n"

# -----------------------------------------------------------------------------
# 5. Batch Rendering (NEW)                                                 {{{1
# -----------------------------------------------------------------------------

function gettime {
	printf $(date +%Y-%m-%d-%H:%M:%S)
}

while IFS= read -r line; do
	# Check if it's a comment
	if [ "${line:0:1}" == "#" ]; then
		continue
	fi

	# Split for an object
	name=$(echo "$line" | sed "s/\(.*\),.*,.*,.*,.*,.*/\1/")
	folder=$(echo "$line" | sed "s/.*,\(.*\),.*,.*,.*,.*/\1/")
	mode=$(echo "$line" | sed "s/.*,.*,\(.*\),.*,.*,.*/\1/")
	value=$(echo "$line" | sed "s/.*,.*,.*,\(.*\),.*,.*/\1/")
	preset=$(echo "$line" | sed "s/.*,.*,.*,.*,\(.*\),.*/\1/")
	acodec=$(echo "$line" | sed "s/.*,.*,.*,.*,.*,\(.*\)/\1/")

	# Go into the folder and start rendering away
	cd "${SPATH}/${folder}"

	# Go through every AVI and process

	# for F in $(find *.avi -type f -print 2> /dev/null | xargs -r0 echo); do

	# Fucking cheat. I'm tired.
	IFS=$'\n'
	for F in $(ls -1 *".avi" 2> /dev/null); do
		# Skip the file if it already exists in the "processed" directory
		if [ ! -e "${SPATH}/processed/${F/avi/mkv}" ]; then
			printf \
				"[%s] Processing %s...\n" \
				"$(gettime)" \
				"$F"

			# STEP 1: Get Audio Amplification (if enabled)
			printf \
				"[%s]     [AUDIO] Volume amp: " \
				"$(gettime)"

			AMPLIFY_AMT="0"

			if [ $NORMALISE -ne 0 ]; then
				# Have FFMPEG take a look...
				${ffmpeg} \
					-hide_banner       \
					-i "$F"            \
					-af "volumedetect" \
					-f null NUL        \
					2> "audio_info.dat"

				# Set Amplification accordingly
				AMPLIFY_AMT=$(cat audio_info.dat \
					| grep "max_volume" \
					| sed 's/.*-\(.*\) dB/\1/'
				)

				# Clean up
				rm audio_info.dat
			fi

			printf "%sdB\n" "$AMPLIFY_AMT"

			# STEP 2: Begin rendering video
			printf \
				"[%s]     [VIDEO] Rendering via ffmpeg (%s %s w/ %s):\n" \
				"$(gettime)" \
				"$value" "$mode" \
				"$acodec"

			if [ "$mode" == "cbr" ]; then
				# We are encoding with a bitrate
				${ffmpeg} \
					-hide_banner                              \
					-v              quiet                     \
					-stats                                    \
					-y                                        \
					-i              "$F"                      \
					-map            0:0                       \
					-map            0:1                       \
					-strict         -2                        \
					-vcodec         ${CODEC}                  \
					-pix_fmt        ${PIX_FMT}                \
					-vf             fps=60                    \
					-af             "volume=${AMPLIFY_AMT}dB" \
					-b:v            $value                    \
					-maxrate        $value                    \
					-bufsize        $value                    \
					-preset         $preset                   \
					-c:a            $acodec                   \
					-x265-params    log-level=error           \
					-metadata:s:a:0 title="Game Audio"        \
					"${SPATH}/processed/${F/avi/mkv}"
			elif [ "$mode" == "crf" ]; then
				# We are encoding with variable bitrate
				${ffmpeg} \
					-hide_banner                              \
					-v              quiet                     \
					-stats                                    \
					-y                                        \
					-i              "$F"                      \
					-map            0:0                       \
					-map            0:1                       \
					-strict         -2                        \
					-vcodec         ${CODEC}                  \
					-pix_fmt        ${PIX_FMT}                \
					-vf             fps=60                    \
					-af             "volume=${AMPLIFY_AMT}dB" \
					-crf            $value                    \
					-preset         $preset                   \
					-c:a            $acodec                   \
					-x265-params    log-level=error           \
					-metadata:s:a:0 title="Game Audio"        \
					"${SPATH}/processed/${F/avi/mkv}"
			fi

			printf \
				"[%s] Render Job Done!\n" \
				"$(gettime)"
		fi
	done

	cd "${SPATH}"
done < "settings.dat"

exit 1

# -----------------------------------------------------------------------------
# 5. Batch Rendering (LEGACY)                                              {{{1
# -----------------------------------------------------------------------------

# Define our folders and bitrates first
folders=()
bitrates=()
names=()
acodecs=()
crfs=()
presets=()
num_dir=0

TIME_STR=""

function main {
	# Add our directories
	# add_directory "Misc"    "12000k" "queue/misc"
	add_directory "Bluray"  "18000k" "queue/bluray"  "flac" "18" "slow"
	add_directory "Regular" "12000k" "queue/regular" "flac" "23" "medium"

	# Print out our fancy intro
	# intro

	# Process all of the directories
	for ((i=0;i<${#folders[@]};i++)); do
		scan "${folders[$i]}" "${bitrates[$i]}" "${names[$i]}" "${acodecs[$i]}" "${crfs[$i]}" "${presets[$i]}"
	done
}

function add_directory {
	#
	# Function   : "add_directory"
	# Synopsis   : add_directory(name, bitrate, path, acodec, crf, preset)
	# Description: Adds a directory in to the queue for rendering.
	#
	
	names[$num_dir]=$1
	bitrates[$num_dir]=$2
	folders[$num_dir]=$3
	acodecs[$num_dir]=$4
	crfs[$num_dir]=$5
	presets[$num_dir]=$6
	let "num_dir++"
}

function scan {
	#
	# Function   : "scan"
	# Synopsis   : scan(path, bitrate, name, acodec, crf)
	# Description: Scans directory for files, and renders them.
	#
	
	path=$1
	bitrate=$2
	name=$3
	acodec=$4
	crf=$5
	preset=$6

	printf "[%s] Scanning %s directory\n" "$(gettime)" "$3"

	farr=("$path/*.avi")
	for file in $farr; do
		render "$1" "$file" "$bitrate" "$acodec" "$crf" "$preset"
	done
}

function render {
	#
	# Function   : "render"
	# Synopsis   : render(file_path, bitrate, acodec, crf)
	# Description: Computes audio amplification by searching for the peak point of
	#              audio via ffmpeg. Then calls ffmpeg again to render video.
	#
	
	dir=$1
	file_path=$2
	#file_name=$(echo "$file_path" | rev | cut -d"/" -f1 | rev)
	file_name=$(basename "$file_path")
	bitrate=$3
	acodec=$4
	crf=$5
	preset=$6

	if [ ! -e "./processed/${file_name/.avi/.mkv}" ]; then
		printf \
			"[%s] Processing %s...\n" \
			"$(gettime)" \
			"$file_name"

		printf \
			"[%s]     [AUDIO] Volume amp: " \
			"$(gettime)"

		printf "%sdB\n" 0

		if [ $crf -eq 0 ]; then
			printf \
				"[%s]     [VIDEO] Rendering via ffmpeg (x264 @ %s CBR w/ %s):\n" \
				$(gettime) \
				"$bitrate" \
				"$acodec"

			${ffmpeg} \
				-hide_banner                         \
				-v quiet                             \
				-stats                               \
				-y                                   \
				-i              "$dir/$file_name"    \
				-map            0:0                  \
				-map            0:1                  \
				-strict -2                           \
				-vcodec         ${CODEC}             \
				-pix_fmt        ${PIX_FMT}           \
				-vf             fps=60               \
				-b:v            $bitrate             \
				-maxrate        $bitrate             \
				-bufsize        $bitrate             \
				-c:a            $acodec              \
				-metadata:s:a:0 title="Game Audio"   \
				"./processed/${file_name/.avi/.mkv}"
		else
			printf \
				"[%s]     [VIDEO] Rendering via ffmpeg (x264 @ %s CRF w/ %s):\n" \
				$(gettime) \
				"$crf" \
				"$acodec"

			${ffmpeg} \
				-hide_banner                         \
				-v quiet                             \
				-stats                               \
				-y                                   \
				-i              "$dir/$file_name"    \
				-map            0:0                  \
				-map            0:1                  \
				-strict         -2                   \
				-vcodec         ${CODEC}             \
				-pix_fmt        ${PIX_FMT}           \
				-vf             fps=60               \
				-crf            ${crf}               \
				-preset         $preset              \
				-c:a            $acodec              \
				-metadata:s:a:0 title="Game Audio"   \
				"./processed/${file_name/.avi/.mkv}"
		fi

		printf \
			"[%s] Render Job Done!\n" \
			"$(gettime)"

		# If there are any extra audio files, convert to FLAC and process
		i=0
		cmd=""
		map=""
		metadata=""
		while [ -e "$dir/${file_name/.avi/} st${i} ("*").wav" ]; do
			printf \
				"[%s] Found Additional Audio Track: %s\n" \
				"$(gettime)"                              \
				"$dir/${file_name/.avi/} st${i} ("*").wav"

			title=$(ls "${dir}/${file_name/.avi/} st${i} ("*").wav" | sed -e 's/.*(\(.*\)).*$/\1/')

			${ffmpeg} \
				-hide_banner                                    \
				-v quiet                                        \
				-stats                                          \
				-y                                              \
				-i "${dir}/${file_name/.avi/} st${i} ("*").wav" \
				-acodec flac                                    \
				"./processed/__AUDIO_tmp${i}.flac"

			cmd="${cmd} -i \"./processed/__AUDIO_tmp${i}.flac\""
			let "i++"
			map="${map} -map ${i}:a"
			metadata="${metadata} -metadata:s:a:${i} title=\"${title}\""
		done

		# Append to the original file by making a copy, then overwriting
		if [ $i -gt 0 ]; then
			echo "${cmd}"
			echo "${map}"
			eval "${ffmpeg} -hide_banner -i \"./processed/${file_name/.avi/.mkv}\" ${cmd} -map 0:v -map 0:a ${map} ${metadata} -c copy \"./processed/tmp.mkv\""
			rm "processed/__AUDIO_tmp"*".flac"
			mv "./processed/tmp.mkv" "./processed/${file_name/.avi/.mkv}"
		fi

		# Generate a json file
		./gen_json.sh "./processed/${file_name/.avi/.mkv}" > "./processed/json/${file_name/.avi/.json}"
	fi
}

function gettime {
	printf $(date +%Y-%m-%d-%H:%M:%S)
}

function intro {
	echo "*"
	echo "* Dxtory Rendering Script for MW2 Gameplay (UNIX Version)"
	echo "*"
	echo "* Just sit back for now and let me do the work for you! I'll be scanning"
	echo "* the following directories and then rendering AVIs (in this order):"
	for ((i=0;i<${#folders[@]};i++)); do
		printf "*     %-10s  %-16s %-6s (%s bitrate)\n" ${names[$i]} ${folders[$i]} ${acodecs[$i]} ${bitrates[$i]}
	done
	echo "*"
	echo "* It'll probably take a while, so I hope you have something to do while"
	echo "* I work. :) Expect your results to be in the \"processed\" directory!"
	echo "*"
	echo ""
}

# Finally, start the damn program.
main
