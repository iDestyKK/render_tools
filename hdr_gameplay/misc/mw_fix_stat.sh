#!/bin/bash

for F in ModernWarfare*.mkv; do
	FDATE=$(\
		ffmpeg -i "$F" \
			2>&1 \
			| grep "DATE_ENCODED" \
			| sed 's/^.*: 20\(.*-.*-.*\) \(.*:.*\):\([0-9][0-9]\).*$/\1\2.\3/' \
			| sed 's/[-:]//g'
	)

	touch -m -t "$FDATE" "$F"

	RES=$?

	if [ $RES -ne 0 ]; then
		echo "Error on ${F}"
	fi
done
