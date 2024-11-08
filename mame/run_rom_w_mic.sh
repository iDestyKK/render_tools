#!/bin/bash

if [ $# -ne 1 ]; then
	printf "usage: %s rom\n" "$0"
	exit 1
fi

# -----------------------------------------------------------------------------
# Metadata                                                                 {{{1
# -----------------------------------------------------------------------------

# Change these to your respective ALSA output devices to record
DEV_0="alsa_output.platform-fef00700.hdmi.hdmi-stereo.monitor"
DEV_1="alsa_input.usb-Kingston_HyperX_QuadCast_S_4101-00.analog-stereo"

# Track titles in the MKA file
TRK_0="Audio - Desktop"
TRK_1="Audio - HyperX QuadCast S"

# Immediate timestamp for "DATE_RECORDED"
DATE_TS="$(date '+%s.%N')"

# -----------------------------------------------------------------------------
# Record                                                                   {{{1
# -----------------------------------------------------------------------------

touch stop

< ./stop ffmpeg \
	-f pulse -i "$DEV_0" \
	-f pulse -i "$DEV_1" \
	-map 0 -map 1 \
	-c:a copy -copyts \
	-metadata DATE_RECORDED="$(date -d "@${DATE_TS}" +%Y-%m-%dT%H:%M:%S.%N%:z)" \
	-metadata:s:a:0 title="$TRK_0" \
	-metadata:s:a:1 title="$TRK_1" \
	"tmp.mka" &

mame "$1" -record inputs.inp -skip_gameinfo

echo "q" > stop

# -----------------------------------------------------------------------------
# Process the Delays                                                       {{{1
# -----------------------------------------------------------------------------

I=0
INITIAL="0"
FILTER=""
MAP=""
DELAYS="$(\
	ffprobe \
		-loglevel quiet \
		-select_streams a \
		-show_entries stream=start_time \
		-of csv=p=0 \
		-i "tmp.mka"\
)"

for DELAY in $DELAYS; do
	if [ $I -eq 0 ]; then
		INITIAL="$DELAY"
		DELTA="0"
		MAP="-map \"[ch${I}]\""
		FILTER="[0:a:${I}]adelay=delays=${DELTA}:all=1[ch${I}]"
	else
		DELTA="$(echo "$INITIAL $DELAY" | awk '{ printf("%d", ($2 - $1) * 1000); }')"
		MAP="${MAP} -map \"[ch${I}]\""
		FILTER="${FILTER};[0:a:${I}]adelay=delays=${DELTA}:all=1[ch${I}]"
	fi
	let "I++"
done

echo "$FILTER"

# -----------------------------------------------------------------------------
# Correct and Compress                                                     {{{1
# -----------------------------------------------------------------------------

eval "ffmpeg -i \"tmp.mka\" -filter_complex \"${FILTER}\" ${MAP} -c:a flac -compression_level 12 -metadata DATE_ENCODED=\"$(date +%Y-%m-%dT%H:%M:%S.%N%:z)\" -metadata:s:a:0 title=\"${TRK_0}\" -metadata:s:a:1 title=\"${TRK_1}\" -metadata:s:a:2 title=\"${TRK_2}\" -metadata:s:a:3 title=\"${TRK_3}\" \"stems.mka\""

# -----------------------------------------------------------------------------
# Generate other info                                                      {{{1
# -----------------------------------------------------------------------------

mv ~/.mame/inp/inputs.inp .

{
	printf "{\n"
	printf "\t\"mame_ver\": \"%s\",\n" "$(mame -version)"
	printf "\t\"rom\": \"%s\",\n" "$1"
	printf "\t\"timestamp\": {\n"

	printf "\t\t\"MAME\": \"%s\",\n" "$(stat "inputs.inp" | grep "Birth: " | sed 's/.*: \(.*-.*-.*\) \(.*:.*:.*\..*\) \(.*\)\(..\)$/\1T\2\3:\4/')"
	printf "\t\t\"AUDIO\": \"%s\"\n" "$(date -d "@${DATE_TS}" +%Y-%m-%dT%H:%M:%S.%N%:z)"

	printf "\t}\n"
	printf "}\n"
} > info.json

# -----------------------------------------------------------------------------
# Finalise                                                                 {{{1
# -----------------------------------------------------------------------------

TS_FN="$(date -d "@${DATE_TS}" "+[%Y-%m-%d - %H %M %S]")"

# Create TAR of entire session
tar -cf "${TS_FN} ${1}.tar" inputs.inp stems.mka info.json
rm inputs.inp stems.mka tmp.mka info.json stop
xz -9ve "${TS_FN} ${1}.tar"
