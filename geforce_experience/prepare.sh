#!/bin/bash
#
# Generates audio files to help prepare GeForce Experience footage
#
# Description:
#     In GeForce Experience, the user has the choice of 2 audio tracks in the
#     file. If selected, this script will extract both of those into their own
#     files. Namely "$FILE stX (Game Audio).aac" and
#     "$FILE st0 (Voice - Game).aac" will be generated. These are reference
#     tracks that can be used to align audio recorded in Audacity if needed.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# Colours
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
normal=$(tput sgr 0)

# Configure FFmpeg
CONFIG="-hide_banner -loglevel error -stats"

# Get Script Path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Go into the queue directory
cd "$SCRIPTPATH/queue"

for F in *.mp4; do
	F1="${F/.mp4/ stX (Game Audio).aac}"
	F2="${F/.mp4/ st0 (Voice - Game).aac}"
	ARGS=""

	printf "%s...\n" "$F"

	# Generate FFmpeg arguments
	printf "  [CHECK] TRK 1: "
	if [ ! -e "$F1" ]; then
		ARGS="$ARGS -map 0:1 -c copy \"$F1\""
		printf "${yellow}CREATE${normal}\n"
	else
		printf "${green}EXISTS${normal}\n"
	fi

	printf "  [CHECK] TRK 2: "
	if [ ! -e "$F2" ]; then
		ARGS="$ARGS -map 0:2 -c copy \"$F2\""
		printf "${yellow}CREATE${normal}\n"
	else
		printf "${green}EXISTS${normal}\n"
	fi

	# Files already exist? Skip
	if [ -z "$ARGS" ]; then
		printf "  [PROC ] ${yellow}SKIP${normal}\n\n"
		continue
	else
		printf "  [PROC ] ${green}GENERATE${normal}\n"
	fi

	# Fine. Execute away.
	printf "  [PROC ] Executing FFmpeg...\n"
	eval "ffmpeg $CONFIG -i \"$F\" $ARGS"

	printf "\n"
done
