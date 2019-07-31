#!/bin/bash
#
# FFMPEG-powered Batch Renderer
# Version 2.0.0 (Last Updated: 2019/07/30)
#
# Description:
#     Renders all AVI videos in "queue" as MKV files into "processed". Any
#     already-rendered videos will be skipped.
#
# Valid Parameters:
#     adhjmv45
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
JSON_EXPORT=0
MULTITRACK=0

# Where are we?
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
UTIL="${SPATH}/../util"
ffmpeg="${UTIL}/ffmpeg.exe"
PR="${SPATH}/processed"

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
	printf "Usage: %s [-adhjmv45]\n\n" "$0"

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
		"-j" "Enable JSON Extra Data"
	printf "  %-4s %s\n" \
		"-m" "Enable Multitrack Audio Detection"
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

			j)
				# Enable JSON Extra Data
				JSON_EXPORT=1
				;;

			m)
				# Enable Multitrack Audio Detection
				MULTITRACK=1
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

# TODO: Clean up (Oh god...)

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
if [ $MULTITRACK != 0 ]; then
	printf "[ ${yellow}%-11s${normal} ]" "on"
else
	printf "[ ${green}%-11s${normal} ]" "off"
fi
printf " [ %-11s ]\n" "off"

# JSON Extra Data
printf "  %-32s " "JSON Extra Data"
if [ $JSON_EXPORT != 0 ]; then
	printf "[ ${yellow}%-11s${normal} ]" "on"
else
	printf "[ ${green}%-11s${normal} ]" "off"
fi
printf " [ %-11s ]\n" "off"

# Container Format
printf "  %-32s " "Container Format"
printf "[ ${green}%-11s${normal} ]" "mkv"
printf " [ %-11s ]\n" "mkv"

printf "\n"

# -----------------------------------------------------------------------------
# 5. Batch Rendering                                                       {{{1
# -----------------------------------------------------------------------------

function gettime {
	printf $(date +%Y-%m-%d\ -\ %H:%M:%S)
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
	for F in *.avi; do
		# Get filename of new MKV file to be made
		MKV_F="${F/.avi/.mkv}"

		# Skip the file if it already exists in the "processed" directory
		if [ ! -e "${PR}/${MKV_F}" ]; then
			printf \
				"[%s] Processing %s...\n" \
				"$(gettime)" \
				"$F"

			# STEP 1: Get Audio Amplification (if enabled)
			printf \
				"[%s]     [${green}AUDIO${normal}] Volume amp: " \
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
			fi

			printf "%sdB\n" "$AMPLIFY_AMT"

			# STEP 2: Begin rendering video
			printf \
				"[%s]     %s Rendering via ffmpeg (%s %s w/ %s):\n" \
				"$(gettime)" \
				"[${green}VIDEO${normal}]" \
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
					"${PR}/__RENDER.mkv"
			elif [ "$mode" == "crf" ]; then
				# We are encoding with variable bitrate
				${ffmpeg} \
					-hide_banner                              \
					-v              quiet                     \
					-stats                                    \
					-y                                        \
					-i              "$F"                      \
					-pattern_type   none                      \
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
					-x265-params    log-level=info            \
					-metadata:s:a:0 title="Game Audio"        \
					"${PR}/__RENDER.mkv"
			fi


			echo ""

			# STEP 3: Additional Audio Track Processsing

			if [ $MULTITRACK -eq 1 ]; then
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
					${ffmpeg} \
						-hide_banner                     \
						-v quiet                         \
						-y                               \
						-i "${F/.avi/} st${i} ("*").wav" \
						-acodec flac                     \
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
					eval "${ffmpeg} -hide_banner -v quiet -stats -i \"${PR}/__RENDER.mkv\" ${cmd} -map 0:v -map 0:a ${map} ${metadata} -c copy \"${PR}/tmp.mkv\""

					# Cleanup and Overwrite
					rm "${PR}/__AUDIO_tmp"*".flac"
					mv \
						"${PR}/tmp.mkv" \
						"${PR}/__RENDER.mkv"
					echo ""
				fi
			fi

			# STEP 4: Generate JSON file for the newly created video file
			if [ $JSON_EXPORT -eq 1 ]; then
				printf \
					"[%s]     %s Generating JSON... " \
					"$(gettime)"                      \
					"[${yellow}EXTRA${normal}]"

				"${UTIL}/gen_json.sh" \
					"$PR/__RENDER.mkv" \
					| sed "s/__RENDER/${F/.avi/}/" \
					> "${PR}/json/${F/.avi/.json}"

				printf "Done!\n"
			fi

			# Wow...
			mv "${PR}/__RENDER.mkv" "${PR}/${MKV_F}"

			printf \
				"[%s]     [${green}NOTIC${normal}] Render Job Done!\n\n\n" \
				"$(gettime)"

			# Clean up
			if [ $NORMALISE -ne 0 ]; then
				rm audio_info.dat
			fi
		fi
	done

	cd "${SPATH}"
done < "${SPATH}/settings.dat"
