# FFmpeg tools for Zoom recordings

## Synopsis
Scripts written for dealing with Zoom recordings. These are mostly for archival
purposes for your typical data hoarder.

## Software Required
The following is needed:

* OBS
* Zoom

You need to record with OBS **and** Zoom simultaneously to utilise scripts
here. **Zoom must be configured to record everyone's voices separately.**
The OBS recording's audio will be used as a resource for aligning the Zoom
separate audio channels properly.

## compile.sh

### Usage/Parameters
```bash
UNIX> ./compile.sh video_file audio_dir chat
```

It will **always** output a `final.mkv` as of now.

### Video File Input
The given `video_file` is the OBS recording. This file must be the **original**
recording without any modifications. The script will grab the **Birth**
timestamp from the file's metadata which may be used to generate an SRT
subtitle file out of the chat data specified later.

### Audio Directory
The `audio_dir` points to a directory full of FLAC files of a format similar to
Dxtory audio extractor (e.g. `st0 Voice - iDestyKK.flac`).

Here is what a sample directory may look like:
```
st0 Voice - iDestyKK.flac
st1 Voice - Person 2.flac
st2 Voice - Person 3.flac
st3 Voice - Person 4.flac
st4 Computer Audio.flac
st5 Reference.flac
```

As long as the file obeys the Dxtory-like format above and the files are FLAC,
the other details about the files do not matter. As such, mono, stereo, 5.1,
and even 7.1 tracks are possible. It does not matter and MKV doesn't care.

### Chat file
Zoom recordings will extract a chat log which is to be included in the final
MKV file as an **attachment**. This can be used to generate subtitles later on
if I feel like further developing this script.
