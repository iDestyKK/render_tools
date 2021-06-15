#!/bin/bash

# Parameter check
if [ $# -lt 5 ] || [ $# -gt 6 ]; then
	printf "usage: %s vid_in1 delay1 vid_in2 delay2 [len] vid_out\n" "$0"
	exit 1
fi

# -----------------------------------------------------------------------------
# Setup                                                                    {{{1
# -----------------------------------------------------------------------------

# Input files
VID1="$1"
VID2="$3"
DELAY_POV1=$2
DELAY_POV2=$4

# Get script path
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# BG Layers (layer 02 is generated)
BGLAYER_01="${SCRIPTPATH}/img/5120x2160_10bpc/bg_layer_01.png"
BGLAYER_03="${SCRIPTPATH}/img/5120x2160_10bpc/bg_layer_03.png"

# Masks
MASK_MKMERGE="${SCRIPTPATH}/img/5120x2160_10bpc/blur_maskedmerge.png"

# Misc
BLANK="${SCRIPTPATH}/img/5120x2160_10bpc/black.png"

# -----------------------------------------------------------------------------
# Construct HDR x265 param string                                          {{{1
# -----------------------------------------------------------------------------

# Configure Colour Primaries and Display Luminance
CPRIM_RED="R(32568,16602)"
CPRIM_BLU="B(7520,2978)"
CPRIM_GRE="G(15332,31543)"
CPRIM_WPT="WP(15674,16455)"
LUMINANCE="L(14990000,100)"
MAX_CLL=1499
MAX_FALL=799

# Ok... construct the string
X265_P="colorprim=bt2020:colormatrix=bt2020nc:transfer=smpte2084"
X265_P="${X265_P}:colormatrix=bt2020nc:hdr=1:info=1:repeat-headers=1"
X265_P="${X265_P}:max-cll=${MAX_CLL},${MAX_FALL}:master-display="
X265_P="${X265_P}${CPRIM_GRE}${CPRIM_BLU}${CPRIM_RED}${CPRIM_WPT}${LUMINANCE}"

# -----------------------------------------------------------------------------
# Filter Construction                                                      {{{1
# -----------------------------------------------------------------------------

# Duration of videos
dur1=$(
	ffprobe \
		-v error \
		-select_streams v:0 \
		-show_entries \
		stream=duration \
		-of default=noprint_wrappers=1:nokey=1 \
		"$VID1"
)

dur2=$(
	ffprobe \
		-v error \
		-select_streams v:0 \
		-show_entries \
		stream=duration \
		-of default=noprint_wrappers=1:nokey=1 \
		"$VID2"
)

# Accurate end time based on duration + delay
END1=$(echo "$dur1 $DELAY_POV1" | awk '{ print($1 + $2 - (1 / 60)); }')
END2=$(echo "$dur2 $DELAY_POV2" | awk '{ print($1 + $2 - (1 / 60)); }')

echo "END1: $END1"
echo "END2: $END2"

# Determine ending time, if argument counter isn't 6
if [ $# -ne 6 ]; then
	VLEN=$(echo "$END1 $END2" | awk '{ print(($1 > $2) ? $1 : $2); }')
else
	VLEN=$5
fi

FILTER=""
FG_FILTER=""
BG_FILTER=""
BG_LAYER_02_F=""

# Video Delaying BS
FILTER="[0:v]setpts=PTS+$DELAY_POV1/TB,split[v0a][v0b]"
FILTER="$FILTER;[1:v]setpts=PTS+$DELAY_POV2/TB,split[v1a][v1b]"

# Construct bg_layer_02 based on videos and blurring
#BG_LAYER_02_F="[v0a]scale=5120:-1,fps=60[preblur_left]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[v1a]scale=5120:-1,fps=60[preblur_right]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[preblur_left]boxblur=luma_radius=150:luma_power=2[blur_left]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[preblur_right]boxblur=luma_radius=150:luma_power=2[blur_right]"

#BG_LAYER_02_F="[v0a]overlay=eof_action=pass,boxblur=luma_radius=75:luma_power=2[preblur_left]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[v1a]overlay=eof_action=pass,boxblur=luma_radius=75:luma_power=2[preblur_right]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[preblur_left]scale=5120:-1,fps=60[blur_left]"
#BG_LAYER_02_F="$BG_LAYER_02_F;[preblur_right]scale=5120:-1,fps=60[blur_right]"

# Alpha blending
BG_LAYER_02_F="[v0a]crop=in_w*.67:in_h[v0_crop]"
BG_LAYER_02_F="$BG_LAYER_02_F;[v1a]crop=in_w*.67:in_h[v1_crop]"
BG_LAYER_02_F="$BG_LAYER_02_F;[5:v][v0_crop]overlay=x=0:y=0:eof_action=pass,format=gbrp[l_pre_fade]"
BG_LAYER_02_F="$BG_LAYER_02_F;[5:v][v1_crop]overlay=x=main_w-overlay_w:y=0:eof_action=pass,format=gbrp[r_pre_fade]"
BG_LAYER_02_F="$BG_LAYER_02_F;[l_pre_fade][r_pre_fade][4:v]maskedmerge[pre_blur]"
BG_LAYER_02_F="$BG_LAYER_02_F;[pre_blur]boxblur=luma_radius=75:luma_power=2[post_blur]"
BG_LAYER_02_F="$BG_LAYER_02_F;[post_blur]scale=5120:-1,fps=60[post_scale]"

# Final merge
BG_LAYER_02_F="$BG_LAYER_02_F;[2:v][post_scale]overlay[blur_layer]"
BG_FILTER="${BG_LAYER_02_F};[blur_layer][3:v]overlay[bg]"

# Foreground

# Scale the videos
FG_FILTER="[v0b]scale=2420:-1,fps=60[pov1]"
FG_FILTER="${FG_FILTER};[v1b]scale=2420:-1,fps=60[pov2]"

# Move them into the appropriate spots
FG_FILTER="${FG_FILTER};[bg][pov1]overlay=x=96:y=96:eof_action=pass[ov1]"
FG_FILTER="${FG_FILTER};[ov1][pov2]overlay=x=2616:y=1055:eof_action=pass[ov2]"

# Put together
FILTER="$FILTER;$BG_FILTER;$FG_FILTER"

# Finalise HDR10 information
FILTER="$FILTER;[ov2]scale=in_range=full:out_range=full:out_color_matrix=bt2020:out_h_chr_pos=0:out_v_chr_pos=0,format=yuv420p10[out_v]"

echo "$FILTER"

# -----------------------------------------------------------------------------
# FFmpeg Execution                                                         {{{1
# -----------------------------------------------------------------------------

if [ $# -eq 6 ]; then
	# Ok have at it
	ffmpeg \
		-i "$VID1" \
		-i "$VID2" \
		-r 60 -i "$BGLAYER_01" \
		-r 60 -i "$BGLAYER_03" \
		-r 60 -i "$MASK_MKMERGE" \
		-loop 1 -r 60 -i "$BLANK" \
		-color_range pc \
		-filter_complex "$FILTER" \
		-x265-params "${X265_P}" \
		-crf 17 \
		-map "[out_v]" \
		-c:v libx265 \
		-pix_fmt yuv420p10le \
		-metadata DATE_ENCODED="$(date +%Y-%m-%dT%H:%M:%S.%N%:z)" \
		-t $5 \
		"$6"
else
	# Ok have at it
	ffmpeg \
		-i "$VID1" \
		-i "$VID2" \
		-r 60 -i "$BGLAYER_01" \
		-r 60 -i "$BGLAYER_03" \
		-r 60 -i "$MASK_MKMERGE" \
		-loop 1 -r 60 -i "$BLANK" \
		-color_range pc \
		-filter_complex "$FILTER" \
		-x265-params "${X265_P}" \
		-crf 17 \
		-map "[out_v]" \
		-c:v libx265 \
		-pix_fmt yuv420p10le \
		-metadata DATE_ENCODED="$(date +%Y-%m-%dT%H:%M:%S.%N%:z)" \
		-t $VLEN \
		"$5"
fi
