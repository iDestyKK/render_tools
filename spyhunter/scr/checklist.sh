#!/bin/bash
#
# Video Checklist
#
# Description:
#     Generates an ASCII-style'd checklist that tells what files exist for each
#     level in SpyHunter. If a level's row has all "OK", it can be compiled via
#     "compile.sh". This script is just a Quality-of-Life way to tell if a
#     video is ready without having the user go to each and every directory.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Setup                                                                    {{{1
# -----------------------------------------------------------------------------

# Setup our pretty colours
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
normal=$(tput sgr 0)

# Get script path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Other params
MAX_LEN=28

# -----------------------------------------------------------------------------
# Helper Functions                                                         {{{1
# -----------------------------------------------------------------------------


#
# check_file                                                               {{{2
#
# C Syntax:
#     void check_file(path)
#
# Description:
#     Checks if a file at "path" exists. If so, it prints "[   OK   ]". If not,
#     it prints "[NO EXIST]". No newline is applied at the end. A space is
#     applied before "[".
#

function check_file {
	if [ -e "$1" ]; then
		printf " [  ${green}OK${normal}  ]"
	else
		printf " [ ${red}FAIL${normal} ]"
	fi
}

#
# check_vid                                                                {{{2
#
# C Syntax:
#     void check_vid(title, dir)
#
# Description:
#     Checks a video for existing files and prints out the details. For each
#     video, there are two variants: raw and watermark. Both will be listed.
#

function check_vid {
	printf "%-*s" $MAX_LEN "$1"

	# raw check
	check_file "$2/$1/segments/raw/intro.mkv"
	check_file "$2/$1/segments/raw/mission.mkv"
	check_file "$2/$1/segments/raw/end_mov.mkv"
	check_file "$2/$1/segments/raw/clear.mkv"

	printf "  "

	# watermark check
	check_file "$2/$1/segments/watermark/intro.mkv"
	check_file "$2/$1/segments/watermark/mission.mkv"
	check_file "$2/$1/segments/watermark/end_mov.mkv"
	check_file "$2/$1/segments/watermark/clear.mkv"

	printf "  "

	# other data
	check_file "$2/$1/audio/stereo.flac"
	check_file "$2/$1/audio/5.1.flac"
	check_file "$2/$1/subtitles/en.srt"
	check_file "$2/$1/data/ffmetadata.txt"

	printf "\n"
}

#
# check_lang                                                               {{{2
#
# C Syntax:
#     void check_lang(title, dir)
#
# Description:
#     Checks a language directory at "dir" for all possible video segments. It
#     will go through all 14 possible levels, check if a directory is there,
#     and show whether or not the segments exist. For verbosity, "title" will
#     also be printed out.
#

function check_lang {
	printf "$1\n"

	# Print header (column ID)
	printf "%-*s " $MAX_LEN " "
	printf "%-9s%-9s%-9s%-9s  " "R__INTRO" "R__MISSI" "R__CINEM" "R__CLEAR"
	printf "%-9s%-9s%-9s%-9s  " "WM_INTRO" "WM_MISSI" "WM_CINEM" "WM_CLEAR"
	printf "%-9s%-9s%-9s%-9s\n" "A_STEREO" "A_5.1"    "ENG_SRT"  "FFMETADT"

	check_vid "01 - Test Track License"   "$2"
	check_vid "02 - Dragon Strike"        "$2"
	check_vid "03 - Route Canal"          "$2"
	check_vid "04 - Swamp Venom"          "$2"
	check_vid "05 - Double Vision"        "$2"
	check_vid "06 - Columbian Extract"    "$2"
	check_vid "07 - IES Testing Facility" "$2"
	check_vid "08 - Escort Service"       "$2"
	check_vid "09 - German Blitz"         "$2"
	check_vid "10 - Terrorist Lock Down"  "$2"
	check_vid "11 - French Kiss"          "$2"
	check_vid "12 - Locked Keys"          "$2"
	check_vid "13 - Venetian Blind"       "$2"
	check_vid "14 - Eye of the Storm"     "$2"

	printf "\n"
}

check_lang "English"  "${SCRIPTPATH}/../English"
check_lang "Japanese" "${SCRIPTPATH}/../Japanese"
