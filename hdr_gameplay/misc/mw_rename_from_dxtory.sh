#!/bin/bash

for F in ModernWarfare*.mkv; do
	FDATE=$(\
		ffmpeg -i "$F" \
			2>&1 \
			| grep "DATE_RECORDED" \
			| sed 's/^.*: \(20.*\)$/\1/;s/T/ - /;s/:/ /g;s/\(.*\)\(- .. ..\).*/\1\2/'
	)

	mv -n "$F" "[${FDATE}].mkv"
done
