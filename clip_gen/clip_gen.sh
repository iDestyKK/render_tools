#!/bin/bash
#
# Clip Generation via varied functions
#
# Description:
#     Root script that will take an input file and run functions based on its
#     contents. Mainly for video generation of several clips.
#
#     This is the root script. All functions must have existing bash scripts
#     in the "func" directory of this bash script. All functions will return
#     a status code and also output text, which can be parsed by this script.
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# Initial                                                                  {{{1
# -----------------------------------------------------------------------------

# Find script install location
script_dir="$( cd "$(dirname "$0")"; pwd -P )"
wrkspc="./__TMP_MKFCSV"

mkdir "$wrkspc" 2> /dev/null
rm -f "$wrkspc/concat.txt"

# -----------------------------------------------------------------------------
# Helper Functions                                                         {{{1
# -----------------------------------------------------------------------------

# Decode a line and call appropriate script to handle it.
function decode_line() {
	# If the line is blank, ignore it
	if [ -z "$1" ]; then
		return
	fi

	# If the line is a comment, ignore it
	FIRST_CHAR="$(printf "%.1s" "$1")"
	if [ "$FIRST_CHAR" == "#" ]; then
		return
	fi

	# Get the name of the function
	FUNC_NAME="$(echo "$1" | sed 's/^\([a-zA-Z0-9_]\+\)(.*);/\1/')"

	# Get arguments as a string
	ARG_LIST="$(echo "$1" | sed 's/^[a-zA-Z0-9_]\+(\(.*\));/\1/')"

	# Construct the function call
	ARG_CALL="$script_dir/func/$FUNC_NAME.sh"

	# Generate hash (for now, let's just assume this is always unique.......)
	HASH="$(
		echo "$FUNC_NAME $ARG_LIST"     \
			| openssl sha256            \
			| sed 's/^.*)= \(.*\)$/\1/' \
			| cut -c1-16
	)"

	# Skip the call entirely if the file already exists
	if [ -e "${wrkspc}/${HASH}.mkv" ]; then
		echo "file '${HASH}.mkv'" >> "${wrkspc}/concat.txt"
		return
	fi

	# Proceed to build the function call. First argument is always the hash
	ARG_CALL="$ARG_CALL $HASH"

	# Rest of the arguments are normal
	OIFS=$IFS
	IFS=',' read -ra ARGC <<< "$(echo "$ARG_LIST" | sed 's/, /,/g')"
	#ARGC=(${ARG_LIST//, / })
	for i in "${ARGC[@]}"; do
		ARG_CALL="$ARG_CALL $i"
	done
	IFS=$OIFS

	eval "$ARG_CALL"
	echo "file '${HASH}.mkv'" >> "${wrkspc}/concat.txt"
}

# -----------------------------------------------------------------------------
# Main Call                                                                {{{1
# -----------------------------------------------------------------------------

IN_SCRIPT="$1"
OUT_MKV="$2"

# Read all lines in the file
readarray -t lines < "$IN_SCRIPT"

# Process all lines
for line in "${lines[@]}"; do
	decode_line "$line"
done

# All processing is done. Go and concatenate
cd __TMP_MKFCSV

# Concatenation
ffmpeg -f concat -safe 0 -i concat.txt -map 0 -c copy "../$OUT_MKV"
STATUS=$?

# Have a nice day
exit $STATUS
