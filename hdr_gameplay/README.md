# Batch HDR Gameplay Video Rendering via FFMPEG

## Synopsis
FFMPEG-powered batch renderer for HDR gameplay footage. This is just like
`gameplay`. It takes AVI files in the `queue` directory and renders it. These
files are stored in the `processed` directory as MKV files.

Unlike `gameplay`, this renderer has no presets. Instead, it encodes via x265
at CRF 16 with the "medium" preset. Videos already rendered will be skipped in
future runs of the script as long as they are present in the `processed`
directory.

## Usage/Parameters
```bash
UNIX> ./hdr_render.sh
```
There are no parameters. Just run it and it'll do everything for you.

## Additional Audio Tracks
MKV allows for multiple audio tracks. To allow for proper archival, you may
specify additional files in a specific format and they will be encoded into the
final MKV. They must follow a strict syntax:
```
gameplay.avi
gameplay st0 (TRACK_NAME).wav
gameplay st1 (TRACK_NAME).wav
gameplay st2 (TRACK_NAME).wav
```
`TRACK_NAME` is replaced with the name. So `gameplay st0 (Voice - DKK).wav` is
valid and will make an audio track named `Voice - DKK` in the final MKV file.
Open the MKV in VLC or any video player of your choice and the tracks will be
in there.

Additional tracks are encoded with **FLAC** with `-compression_level 12`.

### 16 Channel Mode
If the script detects the existance of a `gameplay (16ch).wav`, it will do a
few extra things:

1. A valid 7.1 surround sound audio track will be generated and will replace
   the very first track in the rendered file with it (FLAC compression level
   12).
2. The original 16 channel track will be compressed and appended in as an
   additional audio track. Because FLAC only goes up to 8 channels, TTA (True
   Audio) is used instead. This will appear as the last track in the MKV file.

This is a very experimental mode and used for Modern Warfare (2019) gameplay
where the channel layout is as assumed:
```
00 - SPEAKER_FRONT_LEFT
01 - SPEAKER_FRONT_RIGHT
02 - SPEAKER_FRONT_CENTRE
03 - SPEAKER_LFE
04 - SPEAKER_BACK_LEFT
05 - SPEAKER_BACK_RIGHT
06 - SPEAKER_SIDE_LEFT
07 - SPEAKER_SIDE_RIGHT
08 - SPEAKER_TOP_FRONT_LEFT
09 - SPEAKER_TOP_FRONT_RIGHT
0A - SPEAKER_TOP_BACK_LEFT
0B - SPEAKER_TOP_BACK_RIGHT
0C - SPEAKER_BOTTOM_FRONT_LEFT
0D - SPEAKER_BOTTOM_FRONT_RIGHT
0E - SPEAKER_BOTTOM_BACK_LEFT
0F - SPEAKER_BOTTOM_BACK_RIGHT
```
Apparently bottom (ground) channels aren't even standard. This may update in
the future as I learn more information about how it works.
