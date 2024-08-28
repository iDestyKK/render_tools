#!/bin/bash
#
# AVIF Photo to clip segment
#
# Syntax:
#     photo_avif_shot("file.avif", duration, font_file, w, h, pad_w, pad_h);
#
# Description:
#     Generates a showcase for a photo "file.avif" with a blurred background
#     and photo information on the side. The photo will be showed for a
#     specified number of seconds "duration". The information will be displayed
#     in the font "font_file". The video will be resolution (w x h). There is
#     padding to push the picture and photo information further into the image.
#     The horizontal padding is "pad_w" and the vertical is "pad_h".
#
# Author:
#     Clara Nguyen (@iDestyKK)
#

# -----------------------------------------------------------------------------
# SET ARGUMENTS                                                            {{{1
# -----------------------------------------------------------------------------

ARG_HASH="$1"
ARG_IN_FILE="$2"
ARG_DURATION="$3"
ARG_FONT_FILE="$4"
ARG_W="$5"
ARG_H="$6"
ARG_PAD_W="$7"
ARG_PAD_H="$8"

# -----------------------------------------------------------------------------
# INITIAL SETTING                                                          {{{1
# -----------------------------------------------------------------------------

# Video dimensions
VID_WIDTH=$ARG_W
VID_HEIGHT=$ARG_H

IMG_FRAME_WIDTH=$ARG_W
IMG_FRAME_HEIGHT=$ARG_H

# Image dimensions
IMG_SZ_STR="$(
	ffprobe \
		-i "$ARG_IN_FILE" \
		-v error \
		-select_streams v \
		-show_entries stream=width,height \
		-of csv="p=0:s=x"
)"

IMG_WIDTH=$(echo "$IMG_SZ_STR" | sed 's/^\([0-9]\+\)x\([0-9]\+\).*/\1/')
IMG_HEIGHT=$(echo "$IMG_SZ_STR" | sed 's/^\([0-9]\+\)x\([0-9]\+\).*/\2/')

# Misc
PADDING_W=768
PADDING_H=128

# -----------------------------------------------------------------------------
# IMAGE METADATA                                                           {{{1
# -----------------------------------------------------------------------------

FOCAL_LEN="$(
	exiftool "$ARG_IN_FILE" \
		| grep 'Focal Length' \
		| head -n 1 \
		| sed 's/.*: \([0-9\.]\+\) \(mm\).*/\1\2/;s/\.0mm/mm/'
)"

F_NUMBER="$(
	exiftool "$ARG_IN_FILE" \
		| grep 'F Number' \
		| sed 's/.*: \([0-9\.]\+\).*/\1/'
)"

SHUTTER_SPD="$(
	exiftool "$ARG_IN_FILE" \
		| grep 'Shutter Speed' \
		| head -n 1 \
		| sed 's/.*: \([0-9\.\/]\+\).*/\1/'
)"

ISO="$(
	exiftool "$ARG_IN_FILE" \
		| grep 'ISO' \
		| sed 's/.*: \([0-9\.]\+\).*/\1/'
)"

MODEL="$(
	exiftool "$ARG_IN_FILE" \
		| grep 'Camera Model Name' \
		| sed 's/.*: \(.\+\)/\1/'
)"

OUTPUT_STR1="$MODEL"
OUTPUT_STR2="$FOCAL_LEN  $SHUTTER_SPD  ƒ/$F_NUMBER  ISO $ISO"

if [ $OUTPUT_STR1 == "SM-N975U" ] || [ $OUTPUT_STR1 == "SM-N975UIMX" ]; then
	OUTPUT_STR1="Samsung Galaxy Note 10+"
elif [ $OUTPUT_STR1 == "XQ-DQ72" ]; then
	OUTPUT_STR1="Sony Xperia 1 V"
fi

# -----------------------------------------------------------------------------
# BLURRED BACKGROUND                                                       {{{1
# -----------------------------------------------------------------------------

AA="$IMG_WIDTH $IMG_HEIGHT $VID_WIDTH $VID_HEIGHT"
BLUR_WIDTH="$(echo "$AA" | awk '{ printf("%d\n", $1 * ($4 / $2)); }')"
BLUR_HEIGHT="$(echo "$AA" | awk '{ printf("%d\n", $2 * ($3 / $1)); }')"

# Set crop filter based on which is past image boundaries
if [ $BLUR_WIDTH -ge $VID_WIDTH ]; then
	X="$(echo "$VID_WIDTH $BLUR_WIDTH" | awk '{ printf("%d\n", ($2 - $1) / 2); }')"
	Y=0
	CC="crop=$VID_WIDTH:$VID_HEIGHT:$X:$Y"

	CROP_FILTER="[0:v]format=yuva444p10le,scale=-1:$VID_HEIGHT,$CC,boxblur=50:5[crop_l]"
	CROP_FILTER="${CROP_FILTER};[1:v]format=yuva444p10le,colorchannelmixer=aa=0.35[t]"
	CROP_FILTER="${CROP_FILTER};[crop_l][t]overlay=format=yuv444p10[crop]"
else
	X=0
	Y="$(echo "$VID_HEIGHT $BLUR_HEIGHT" | awk '{ printf("%d\n", ($2 - $1) / 2); }')"
	CC="crop=$VID_WIDTH:$VID_HEIGHT:$X:$Y"

	CROP_FILTER="[0:v]format=yuva444p10le,scale=$VID_WIDTH:-1,$CC,boxblur=50:5[crop_l]"
	CROP_FILTER="${CROP_FILTER};[1:v]format=yuva444p10le,colorchannelmixer=aa=0.35[t]"
	CROP_FILTER="${CROP_FILTER};[crop_l][t]overlay=format=yuv444p10[crop]"
fi

# -----------------------------------------------------------------------------
# IMAGE FITTING IN BOUNDS                                                  {{{1
# -----------------------------------------------------------------------------

# Determine whether to downscale horizontally-based or vertically-based
AA="$IMG_WIDTH $IMG_HEIGHT $IMG_FRAME_WIDTH $IMG_FRAME_HEIGHT $PADDING_W"
IMG_N_WIDTH="$(echo "$AA" | awk '{ printf("%d\n", $1 * (($4 - ($5 * 2)) / $2)); }')"
AA="$IMG_WIDTH $IMG_HEIGHT $IMG_FRAME_WIDTH $IMG_FRAME_HEIGHT $PADDING_H"
IMG_N_HEIGHT="$(echo "$AA" | awk '{ printf("%d\n", $2 * (($3 - ($5 * 2)) / $1)); }')"

# Compute padding bounds
VID_N_WIDTH="$(echo "$IMG_FRAME_WIDTH $PADDING_W" | awk '{ printf("%d\n", $1 - ($2 * 2)); }')"
VID_N_HEIGHT="$(echo "$IMG_FRAME_HEIGHT $PADDING_H" | awk '{ printf("%d\n", $1 - ($2 * 2)); }')"

# Fit into video boundaries and compute overlay (X, Y) pair
IMG_SCALE_FILTER="[0:v]format=yuva444p10le,scale=w=$VID_N_WIDTH:h=$VID_N_HEIGHT"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:in_range=full:out_range=full"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:out_color_matrix=bt2020:out_h_chr_pos=0"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:out_v_chr_pos=0"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:force_original_aspect_ratio=decrease"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER,pad=$VID_N_WIDTH:$VID_N_HEIGHT"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:(( (ow - iw)/2 )):(( (oh - ih)/2 ))"
IMG_SCALE_FILTER="$IMG_SCALE_FILTER:color=0x00000000,format=yuva444p10le,split[img][sh_mk]"

X=$PADDING_W
Y=$PADDING_H
W=$VID_N_WIDTH
H=$VID_N_HEIGHT

# -----------------------------------------------------------------------------
# DROP SHADOW                                                              {{{1
# -----------------------------------------------------------------------------

SH_FILT="[1:v]format=yuva444p10le,colorchannelmixer=aa=0.0[dsm]"
SH_FILT="$SH_FILT;[sh_mk]format=yuva444p10le,colorchannelmixer=rr=0:bb=0:gg=0:aa=0.5[dsp]"
SH_FILT="$SH_FILT;[dsm][dsp]overlay=:x=${X}:y=${Y},boxblur=75[box_shadow]"


# -----------------------------------------------------------------------------
# TEXT                                                                     {{{1
# -----------------------------------------------------------------------------

SCALE="$(
	echo "$IMG_WIDTH $IMG_HEIGHT $VID_N_WIDTH $VID_N_HEIGHT" \
	| awk '{ Mw = $3 / $1; Mh = $4 / $2; printf("%f\n", Mw < Mh ? Mw : Mh); }'
)"

NW="$(echo "$IMG_WIDTH $SCALE" | awk '{ printf("%d\n", $1 * $2); }')"
NH="$(echo "$IMG_HEIGHT $SCALE" | awk '{ printf("%d\n", $1 * $2); }')"
NX="$(echo "$X $VID_N_WIDTH $NW" | awk '{ printf("%d\n", $1 + (($2 - $3) / 2)); }')"
NY="$(echo "$Y $VID_N_HEIGHT $NH" | awk '{ printf("%d\n", $1 + (($2 - $3) / 2)); }')"

TXT="drawtext=fontfile='$ARG_FONT_FILE':text='$OUTPUT_STR2'"
TXT="$TXT:fontcolor=white:fontsize=($VID_HEIGHT * 0.035):y=$NY+$NH-th:x=$NX+$NW + ($VID_HEIGHT * 0.04)"
TXT="$TXT,drawtext=fontfile='$ARG_FONT_FILE':text='$OUTPUT_STR1'"
TXT="$TXT:fontcolor=white:fontsize=($VID_HEIGHT * 0.035):y=$NY+$NH - ($VID_HEIGHT * 0.06875):x=$NX+$NW + ($VID_HEIGHT * 0.04)"

# -----------------------------------------------------------------------------
# FINALISE                                                                 {{{1
# -----------------------------------------------------------------------------

OVERLAY_FILTER="[box_shadow][img]overlay=format=yuv444p10:x=${X}:y=${Y}[mg1]"
OVERLAY_FILTER="${OVERLAY_FILTER};[crop][mg1]overlay=format=yuv444p10,${TXT}"
OVERLAY_FILTER="${OVERLAY_FILTER},setdar=${VID_WIDTH}/${VID_HEIGHT}[out]"

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

ffmpeg \
	-hide_banner \
	-r 60 \
	-i "$ARG_IN_FILE" \
	-f lavfi -i color=size=${VID_WIDTH}x${VID_HEIGHT}:rate=60:color=black \
	-filter_complex "${CROP_FILTER};${IMG_SCALE_FILTER};${SH_FILT};${OVERLAY_FILTER}" \
	-map '[out]' \
	-c:v libx265 \
	-pix_fmt yuv420p10le \
	-preset slow \
	-x265-params "${X265_P}" \
	-t "$3" \
	-crf 0 \
	"__TMP_MKFCSV/${ARG_HASH}.mkv"
