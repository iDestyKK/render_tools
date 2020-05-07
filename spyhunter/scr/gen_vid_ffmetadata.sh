#!/bin/bash
#
# Generate Video FFMetadata
#
# Description:
#     Takes a root directory for an episode (e.g. "03 - Route Canal") and
#     generates a valid "ffmetadata.txt" in the "data" directory based on
#     video files in the "segments/raw" directory.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Error Checking                                                           {{{1
# -----------------------------------------------------------------------------

# Get script path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Argument check
if [ $# -ne 3 ]; then
	printf "usage: %s dir title artist\n" "$0"
	exit 1
fi

# Directory check
if [ ! -e "$1" ]; then
	printf "fatal: \"%s\" does not exist/\n" "$1"
	exit 2
fi

# Directory check
if [ ! -e "$1/data" ]; then
	printf "fatal: \"%s\" does not exist/\n" "$1/data"
	exit 3
fi

# Directory check
if [ ! -e "$1/segments/raw" ]; then
	printf "fatal: \"%s\" does not exist/\n" "$1/segments/raw"
	exit 4
fi

# Helper script check (gen_vid_seconds.sh)
VID_SEC="${SCRIPTPATH}/gen_vid_seconds.sh"
if [ ! -e "${VID_SEC}" ]; then
	printf "fatal: \"%s\" does not exist/\n" "${VID_SEC}"
	exit 5
fi

# -----------------------------------------------------------------------------
# Helper Functions                                                         {{{1
# -----------------------------------------------------------------------------

# void add_frac(num1, num2)
function add_frac {
	printf "%.2f" "$(echo "$1 $2" | awk '{ print $1 + $2 }')"
}

# void sec_to_ts(sec)
function sec_to_ts {
	F="$(echo "$1" | sed 's/.*\.\(.*\)/\1/')"
	D="$(echo "$1" | sed 's/\(.*\)\..*/\1/')"

	S1=0
	S2=0
	S3=0

	let "S1 = D / 3600"
	let "S2 = D / 60"
	let "S3 = D % 60"

	printf "%02s:%02s:%02s.%02s" "$S1" "$S2" "$S3" "$F"
}

# void write_chapter(title, start_sec, end_sec)
function write_chapter {
	# Header
	printf "\n[CHAPTER]\nTIMEBASE=1/1000\n\n"

	# Time Comment
	printf \
		"# Starts at %s, Ends at %s\n" \
		"$(sec_to_ts $2)" \
		"$(sec_to_ts $3)"

	# Variables
	printf "START=%s0\n" "$(echo "$2" | sed 's/\.//')"
	printf "END=%s0\n" "$(echo "$3" | sed 's/\.//')"
	printf "TITLE=%s\n" "$1"
}

# -----------------------------------------------------------------------------
# Part Computation                                                         {{{1
# -----------------------------------------------------------------------------

cd "$1"

PT1_TITLE="Intro"
PT1_START=0
PT1_LEN=$(${VID_SEC} "segments/raw/intro.mkv")
PT1_END=$(add_frac $PT1_START $PT1_LEN)

PT2_TITLE="Gameplay"
PT2_START=$PT1_END
PT2_LEN=$(${VID_SEC} "segments/raw/mission.mkv")
PT2_END=$(add_frac $PT2_START $PT2_LEN)

PT3_TITLE="Level End"
PT3_START=$PT2_END
PT3A_LEN=$(${VID_SEC} "segments/raw/end_mov.mkv")
PT3B_LEN=$(${VID_SEC} "segments/raw/clear.mkv")
PT3_LEN=$(add_frac $PT3A_LEN $PT3B_LEN)
PT3_END=$(add_frac $PT3_START $PT3_LEN)

# -----------------------------------------------------------------------------
# File Generation                                                          {{{1
# -----------------------------------------------------------------------------

# Header
printf \
	";FFMETADATA1\ntitle=%s\nartist=%s\n" \
	"$2" "$3"

write_chapter "$PT1_TITLE" $PT1_START $PT1_END
write_chapter "$PT2_TITLE" $PT2_START $PT2_END
write_chapter "$PT3_TITLE" $PT3_START $PT3_END
