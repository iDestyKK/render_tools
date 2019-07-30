#!/bin/bash

# Figure out where FFMPEG is
SCRIPT=$(readlink -f "$0")
SPATH=$(dirname "$SCRIPT")
ffmpeg="${SPATH}/ffmpeg.exe"

function get_time() {
	cat "__TMP.txt" | grep "Duration:" | sed 's/^.*Duration: \(.*\), start.*$/\1/'
}

function seconds() {
	hour=$(echo "$1" | sed 's/^\(.*\):\(.*\):\(.*\)/\1/')
	min=$(echo "$1" | sed 's/^\(.*\):\(.*\):\(.*\)/\2/')
	sec=$(echo "$1" | sed 's/^\(.*\):\(.*\):\(.*\)/\3/')
	((h=$((10#$hour))*3600))
	((m=$((10#$min))*60))

	echo "$h $m $sec" | awk '{printf("%.2f\n", $1 + $2 + $3)}'
}

# Check if we did our parameters correctly.
if [ $# -ne 1 ]; then
	printf "Usage: $0 filename\n"
	exit 1
fi

# Check if the file exists.
if [ ! -e "$1" ]; then
	printf "[FATAL] File \"$1\" doesn't exist!\n"
	exit 2
fi

# Showtime
${ffmpeg} -i "$1" 2> __TMP.txt

# Parse data and generate the JSON file

# Header
printf "{\n\t\"name\": \"%s\",\n" "$(echo "$1" | sed 's/^.*\/\(.*\)$/\1/')"

# Metadata
printf "\t\"metadata\": {\n"
printf "\t\t\"title\": {\n"
printf "\t\t\t\"en-us\": \"\",\n"
printf "\t\t\t\"jp\": \"\"\n"
printf "\t\t},\n"
printf "\t\t\"%s\": -1,\n"     "rating"
printf "\t\t\"%s\": [],\n"     "identifier"
printf "\t\t\"%s\": \"\""    "comment"

# If there is amplify data in "amplify.dat" then append it here
if [ -e "audio_info.dat" ]; then
	printf ",\n\t\t\"%s\": %s\n"  "amplify" "$(cat audio_info.dat | grep "max_volume" | sed 's/.*-\(.*\) dB/\1/')"
else
	printf "\n"
fi

printf "\t},\n"

# Duration
printf "\t\"%s\": {\n"         "duration"
printf "\t\t\"%s\": \"%s\",\n" "timestamp" "$(get_time)"
printf "\t\t\"%s\": %s\n"      "seconds"   "$(seconds $(get_time))"
printf "\t},\n"

# Filesize
printf "\t\"%s\": %d,\n"         "filesize" $(stat "$1" --printf="%s")

# Streams
# Get information about the track number first
vnum=$(cat __TMP.txt | grep "Stream.*Video" | wc -l)
anum=$(cat __TMP.txt | grep "Stream.*Audio" | wc -l)
fv=0
fa=0
fs=0

printf "\t\"streams\": {\n"

if [ $vnum -gt 0 ]; then
	printf "\t\t\"video\": [\n"

	grep "Stream.*Video" __TMP.txt | while read -r line ; do
		if [ $fv -eq 0 ]; then
			fv=1
		else
			printf ",\n"
		fi
		printf "\t\t\t{\n"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "desc"       "Game Video"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "resolution" "$(echo "$line" | grep -o '[0-9]\{3,4\}x[0-9]\{3,4\}')"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "codec"      "$(echo "$line" | sed -e "s/^.*Video: *//" -e "s/,.*$//")"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "pix_fmt"    "$(echo "$line" | sed -e "s/^.*Video:.*, \(.*\),.*x.*.*$/\1/")"
		printf "\t\t\t\t\"%s\": \"%s\"\n"  "fps"        "$(echo "$line" | grep -o "[0-9]\{1,3\} fps" | sed 's/ fps//')"
		printf "\t\t\t}"
	done

	printf "\n\t\t],\n"
fi

if [ $anum -gt 0 ]; then
	printf "\t\t\"audio\": [\n"

	grep "Stream.*Audio" __TMP.txt | while read -r line ; do
		if [ $fa -eq 0 ]; then
			fa=1
		else
			printf ",\n"
		fi
		printf "\t\t\t{\n"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "desc"        "Game Audio"
		printf "\t\t\t\t\"%s\": \"%s\",\n" "codec"       "$(echo "$line" | sed -e "s/^.*Audio: *//" -e "s/,.*$//")"
		printf "\t\t\t\t\"%s\": %s,\n"     "sample_rate" "$(echo "$line" | grep -o "[0-9]\{1,6\} Hz" | sed "s/ Hz//")"
		printf "\t\t\t\t\"%s\": \"%s\"\n"  "channels"    "$(echo "$line" | grep -oP "Hz, .*?," | sed "s/^.*, \(.*\),.*$/\1/")"
		printf "\t\t\t}"
	done

	printf "\n\t\t]\n"
fi

printf "\t}\n"

printf "}\n"

rm "__TMP.txt"
