#!/bin/bash

if [ $# -ne 1 ]; then
	printf "usage: $0 mkv_file\n"
	exit 1
fi

# Filenames
F="$1"
JSON="${F/mkv/json}"
MASTER="$(dirname "$F")/../queue/${F/mkv/avi}"

# Get FFmpeg information about the file
ffmpeg -i "$F" 2> tmp.txt

# Grab metadata
DATE_REC=$(grep "DATE_RECORDED" "tmp.txt" | sed 's/^.*: //')
DATE_ENC=$(grep "DATE_ENCODED" "tmp.txt" | sed 's/^.*: //')
TS_REC=$(date -d "$DATE_REC" +"%s")
TS_ENC=$(date -d "$DATE_ENC" +"%s")
DURATION="$(grep "^  Duration:" tmp.txt | sed 's/.*Duration: \(.*\), s.*/\1/')"
SEC=$(
	echo "$DURATION" \
	| sed 's/:/ /g' \
	| awk '{printf("%.2f", (3600 * $1) + (60 * $2) + $3)}'
)

# Write the new JSON file
# Opening Brace
printf "{\n"

# Filename
printf "\t\"filename\": \"%s\",\n" "$F"

# Metadata
printf "\t\"metadata\": {\n"
printf \
	"\t\t\"title\": {\n\t\t\t\"%s\": \"\",\n\t\t\t\"%s\": \"\"\n\t\t},\n" \
	"en-gb" "ja-jp"
printf "\t\t\"id\": \"\",\n"
printf "\t\t\"rating\": -1,\n"
printf "\t\t\"identifier\": [],\n"
printf "\t\t\"comment\": \"\",\n"
printf "\t\t\"amplify\": 0.0\n"
printf "\t},\n"

# Date
printf "\t\"date\": {\n"
printf \
	"\t\t\"recorded\": {\n\t\t\t\"iso-8601\": \"%s\",\n\t\t\t\"unix\": %s\n\t\t},\n" \
	"$DATE_REC" "$TS_REC"
printf \
	"\t\t\"encoded\": {\n\t\t\t\"iso-8601\": \"%s\",\n\t\t\t\"unix\": %s\n\t\t}\n" \
	"$DATE_ENC" "$TS_ENC"
printf "\t},\n"

# Duration
printf "\t\"duration\": {\n"
printf \
	"\t\t\"ts\": \"%s\",\n\t\t\"sec\": %s\n" \
	"$DURATION" "$SEC"
printf "\t},\n"

# Filesize
printf "\t\"filesize\": {\n"

# Filesize of original AVI master only if it still exists...
if [ -e "$MASTER" ]; then
	printf \
		"\t\t\"master\": %d,\n" \
		$(stat -c %s "$MASTER")
else
	printf "\t\t\"master\": -1,\n"
fi

# Filesize of encoded MKV before JSON file embedding
printf \
	"\t\t\"encoded\": %d\n" \
	$(stat -c %s "$F")
printf "\t},\n"

# Stream data
ffprobe \
	-v error \
	-show_streams \
	-of json \
	-i "$F" \
	| sed '1d; $d; s/    /\t/g'

# Closure
printf "}\n"

rm tmp.txt
