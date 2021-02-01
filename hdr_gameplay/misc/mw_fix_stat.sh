#!/bin/bash

for F in ModernWarfare*.mkv; do
	FDATE=$(\
		ffmpeg -i "$F" \
			2>&1 \
			| grep "DATE_ENCODED" \
			| sed 's/^.*: \(20.*\)$/\1/'
	)

	touch -m --date="$FDATE" "$F"

	RES=$?

	if [ $RES -ne 0 ]; then
		echo "Error on ${F}"
	fi
done
