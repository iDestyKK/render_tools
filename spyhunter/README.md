# SpyHunter Video "Compilation" via FFMPEG

## Synopsis
Collection of scripts and file structure for how the SpyHunter gameplay videos
on DERPGProductions's YouTube channel were generated. There's a lot of data
that is thrown into the final delivery MKV files, such as the following:

* Lossless Stereo and 5.1 Surround Sound audio tracks (FLAC)
* Chapter Data for each segment
* SRT Subtitles (`en-us`, `en-gb`, and `ja-jp` if possible)

The playthrough consists of playing the game twice. First run is in Japanese
(because the Japanese version has almost no footage on the Internet). Second
run is in English. There are 14 levels overall, so that's 28 videos. However, I
store two versions of each video (with and without watermark), making 56 total.
For YouTube, the watermarked version is uploaded.

5.1 Surround Sound audio track is possible by enabling "Surround" in the audio
settings. The engine utilises Dolby Pro Logic II, which can be dematrix'd into
a 5.0 audio stream via FFmpeg. The .1 (LFE) channel can be trivially created
via running equalisation on a stereo downmix of the 5.0 stream. YouTube
properly stores the 5.1 stream and can play it back on a TV or console.

## Utilities
Inside the `scr` directory, there are a few bash scripts that made this
production much more trivial, as a most of it can be automated.

### checklist.sh
Quality-of-Life script to quickly determine what files are missing for a level
prior to compilation. If a level's row is all "OK"s, running `compile.sh` will
generate the final MKV for upload.

### compile.sh
Goes into each level's directory and, if all of the required files exist, will
generate the final MKV files for uploading to YouTube. Each level has 4 videos
created:

* English - RAW
* English - Watermarked
* Japanese - RAW
* Japanese - Watermarked

The files required are:

* audio/stereo.flac
* audio/5.1.flac
* data/ffmetadata.txt
* segments/raw/{clear,end\_mov,intro,mission}.mkv
* segments/watermark/{clear,end\_mov,intro,mission}.mkv
* subtitles/en.srt

Any files that were already rendered out will be skipped, kinda like GNU make.

### gen\_concat\_audio.sh
```bash
UNIX> ./gen_concat_audio.sh dir
```
Generates a dematrix'd 5.0 audio stream from the video files in the "segments"
directory (the ones required by `compile.sh` above). By default, the video
files store a lossless stereo track which has surround information via Dolby
Pro Logic II. This uses that information to generate the 5.0 stream. The output
file is then used to generate `stereo.flac` and `5.1.flac`.

### gen\_vid\_ffmetadata.sh
```bash
UNIX> ./gen_vid_ffmetadata.sh dir > ffmetadata.txt
```
Generates a `ffmetadata.txt` formatted file to stdout when given a level's
directory. This file can be included in an FFmpeg command to force the final
MKV file to have chapter information. This relies on `gen_vid_seconds.sh`.

### gen\_vid\_seconds.sh
```bash
UNIX> ./gen_vid_seconds.sh video
```
Outputs a `video`'s duration in seconds with decimals preserved.

## Production Procedure
1. Record gameplay via PCSX2 and export to AVI.
2. Encode each section as its own MKV file (watermarked and raw), respectively:
   * **intro.mkv** - Level Description. Weapons/Enemies overview, etc.
   * **mission.mkv** - Mission gameplay.
   * **end\_mov.mkv** - Mission ending cinematic.
   * **clear.mkv** - Mission results screen.
3. Move those MKV files into `$LANG/$LEVEL/segments/raw` and
   `$LANG/$LEVEL/segments/watermark` respectively.
4. Run `./gen_concat_audio.sh` to generate `$LANG/$LEVEL/audio`. This will
   create `5.0.flac`.
5. Create `stereo.flac` and `5.1.flac` from `5.0.flac` in Audacity.
6. Create subtitles via Audacity labels and convert to SRT. Store that in
   `$LANG/$LEVEL/subtitles/en.srt`.
7. Run `./gen_vid_ffmetadata.sh` to generate `ffmetadata.txt`.
8. Run `./compile.sh` to generate delivery MKVs with all information embedded.

It sounds like a lot, but with the tools given, this can be done in seconds for
each video.

## Where's the MKV and FLAC files?
The audio and AVI/MKV file masters will not be uploaded to this repo. The raws
for each segment are well over 50 GB each and I doubt GitHub would let me have
a 1.4 TB repo.