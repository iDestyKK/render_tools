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

### 16 Channel Mode (Dolby Atmos 7.1.4.4)
If the script detects the existence of a `gameplay (16ch).wav`, it will do a
few extra things:

1. A valid 7.1 surround sound audio track will be generated and will replace
   the very first track in the rendered file with it (**FLAC** compression
   level 12).
2. The original 16 channel track will be compressed and appended in as an
   additional audio track. Because **FLAC** only goes up to 8 channels, **TTA
   (True Audio)** is used instead. This track will come right after the 7.1
   surround track mix in the MKV file.

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
This 16 channel layout is known as **7.1.4.4** Spatial Sound according to
Dolby. It features leveling information both above and below the listener. This
is second only to **8.1.4.4** in terms of spatial sound formats. Supposedly
Modern Warfare supports this as well. If it does, expect an update to switch
**TTA (True Audio)** to **WV (WavPack)** for 17 channel support as a
`SPEAKER_BACK_CENTRE` would be nice...

## Subtitle Tracks
MKV allows for subtitle tracks as well. Just like the process for adding
multiple audio tracks, to ensure proper archival, you may specify additional
files in a specific format. They will be encoded into the final MKV. They must
follow a strict syntax:
```
gameplay.avi
gameplay st0 (TRACK_NAME).txt
gameplay st1 (TRACK_NAME).txt
gameplay st2 (TRACK_NAME).txt
```
It's the same as the audio, except replacing `wav` with `txt`.

These subtitle files are label files exported via
[Audacity](https://www.audacityteam.org/) which contain proper `start`,
`finish`, and `text` data needed to generate SRT subtitles. An example of this
would be:
```
0.325079	1.102948	This is a test
1.857596	2.821224	This is also a test lol
```
It's a very simple format. Data is separated by tabs (`\t`) and newlines
(`\n`). Generating an SRT subtitle file from this is done easily via
`tools/txt2srt.cpp`.

### Additional "All-in-one" track

If multiple subtitle files are present, an additional subtitle track will be
generated, `Voice - All`, which combines all other `txt` files together in a
non-conflicting way. This track will be the first subtitle track in the final
MKV file.

### Preservation of the original files

Finally, a `subtitles_txt.tar.xz` will be generated and embedded into the final
MKV file. This archive will contain the original `txt` files exported from
Audacity. The reason for the archival of these files is because the precision
of the timestamps stored in them is far greater than the precision of the
`srt` files generated from them. In addition, the original filenames and
metadata are preserved because that's just how `tar` works.

An FFmpeg output for an MKV file containing such an attachment would look like
this:

```
  Stream #0:22: Attachment: none
    Metadata:
      filename        : subtitle_txt.tar.xz
      mimetype        : application/x-gtar
      title           : Subtitle Raws (Audacity Labels)
```

## Additional Metadata
MKV files allow for `DATE_ENCODED` and `DATE_RECORDED` tags. `hdr_render.sh`
will grab this metadata with nanosecond precision to store in the file. It's
completely overkill, but it's nice to have the exact moment when the recording
started preserved.

An FFmpeg output for an MKV file will contain the following metadata:

```
Input #0, matroska,webm, from 'ModernWarfare 2021-01-31 00-20-59-932.mkv':
  Metadata:
    ISRC            : ...stuff...
    DATE_RECORDED   : 2021-01-31T00:20:59.969497700-05:00
    DATE_ENCODED    : 2021-01-31T18:44:57.483873000-05:00
    ENCODER         : Lavf58.42.102
  Duration: 00:07:03.66, start: 0.000000, bitrate: 29685 kb/s
    Stream #0:0: Video: hevc (Main 10), yuv420p10le(tv, bt2020nc/bt2020/smpte2084, progressive), 2560x1080, 60 fps, 60 tbr, 1k tbn, 60 tbc (default)
```

### Additional scripts
The metadata stored in these MKV files can also be used to rename the file in a
more compact way. On my server, files are normally named
`[YYYY-MM-DD - HH MM] MAP_NAME.mkv`. There's two scripts available which will
assist in this:

1. `mw_fix_stat.sh` - Grabs `DATE_ENCODED` and sets the file's modified date to
   it.

2. `mw_rename_from_dxtory.sh` - Grabs `DATE_RECORDED` and renames the file into
   `[YYYY-MM-DD - HH MM].mkv`. You are expected to put in the map name after
   the `]` character of the filename manually.

Both of these scripts search for MKV files that begin with `ModernWarfare`. On
my end, the following order is recommended for executing these:

```bash
UNIX> ./mw_fix_stat.sh; ./mw_rename_from_dxtory.sh
```

Your MKV deliverables will have their modified date fixed, and then renamed
accordingly.
