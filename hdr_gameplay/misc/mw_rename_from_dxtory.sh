#!/bin/bash

for F in ModernWarfare*.mkv; do
	FDATE=$(\
		ffmpeg -i "$F" \
			2>&1 \
			| grep "DATE_RECORDED" \
			| sed 's/^.*: \(.*-.*-.*\) \(.*:.*\):.*$/\1 - \2/' \
			| sed 's/:/ /'
	)

	mv -n "$F" "[${FDATE}].mkv"
done
