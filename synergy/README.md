# Synergy (HL2 Co-Op Mod) Split-Screen Rendering via FFmpeg

## Synopsis
Source and FFmpeg-powered footage generation for Synergy gameplay. This
**requires** 4 players and the final footage will be the 4 POVs put in
split-screen format across a 3840x2160 video. The end-user is given control
over specifying length of the video, as well as delay for each POV to ensure
every perspective is perfectly aligned. On top of that, DEM files and a JSON
information file are attached to the final MKV file for the ultimate archiving
solution.

## Preview
![Screenshot](https://github.com/iDestyKK/render_tools/blob/assets/synergy/preview.png)

## Utilities
In this directory, there's some bash scripts which need to be used for a final
MKV to be generated.

### dem2tga.sh
```bash
UNIX> ./dem2tga.sh game_exe mod_dir dem_path local_dir
```
Writes all frames in a dem file at `dem_path` to a directory pointed at
`local_dir`. The format for the frames is `frame%04d.tga`. A **stereo** FLAC
S16 file containing the audio at 44100 hz is also generated.

Specify an **absolute path** to the `game_exe` (the path to `synergy.exe`), as
well as an **absolute path** to the `mod_dir` (the path to `synergy`, in the
same folder as `synergy.exe`). `dem_path` is a **relative path** assuming
`mod_dir` is the working directory. Finally, `local_dir` is a **relative path**
assuming the script's working directory is the working directory.

**For optimal results, set your game's resolution to 1600x900 and have it
running in "Windowed" mode. The final video is 3840x2160 but each player will
have a 1600x900 region in `bg_full.png` to themselves. Do not go to a higher or
lower resolution or else the final video will have obvious
upscaling/downscaling effects and be blurred.**

### encode.sh
```bash
UNIX> ./encode.sh p1_dir p1_delay p1_dem p2_dir p2_delay p2_dem p3_dir p3_delay p3_dem p4_dir p4_delay p4_dem duration output_mkv
```
Generates a final MKV at `output_mkv` combining the perspectives of 4 players.
Each perspective takes 3 arguments: `pX_dir`, `pX_delay`, and `pX_dem`. The
`pX_dir` is simply the directory containing the TGA files for that player's
POV, as well as their `frame.flac` audio. `pX_delay` is the delay **in
seconds** (decimals allowed) before that POV shows up. `pX_dem` is the path to
the player's DEM file for archiving. Lastly, because Source Engine's TGA export
may show some additional information in the last few frames, the user must
specify the video's `duration` **in seconds** (decimals allowed).

## Final MKV Information
This is an archival solution as well as a footage "compiler". The goal is to
preserve as much of the original information as possible. DEMs, timestamps,
original filenames, etc. This is so anyone with access to the MKV files in the
future may go back and re-export the footage at a higher resolution or a higher
framerate if they see fit.

There are 2 files generated by `encode.sh` which are attached to the final MKV:

### info.json
Stores information on when the MKV was encoded, all original timestamps for
when the original DEMs were recorded, the delay applied to each POV, original
filenames, duration, and the video encoding options passed into FFmpeg.

Example `info.json` for `d1_eli_01`:
```json
{
	"date_encoded": "2020-08-02 16:19:16.311920900 -0400",
	"date_recorded": [
		"2018-05-20 17:22:01.270287300 -0400",
		"2018-05-20 17:22:05.507498100 -0700",
		"2018-05-20 17:22:01.625595600 -0500",
		"2018-05-20 17:22:06.821438500 +0200"
	],
	"delay": [ 0, 11.873, 12.823, 12.356 ],
	"dem_fnames": [
		"oh_yes_20.dem",
		"skknergy_3.dem",
		"oh_yes_19.dem",
		"no_3.dem"
	],
	"duration": 461.743,
	"video_encoder_settings": {
		"vcodec": "libx265",
		"pix_fmt": "yuv420p10le",
		"crf": 17
	}
}
```

### demos.tar.xz
A TAR file compressed via XZ containing the original demo (DEM) files used in
the video. Because the naming of the original files may be the same or
confusing, they are renamed to `p1.dem`, `p2.dem`, etc.

Example `demos.tar.xz`:
```bash
UNIX> tar -tv --full-time -f demos.tar.xz
-rw-r--r-- idest/197609 5127651 2018-05-20 17:22:01 p1.dem
-rw-r--r-- idest/197609 5510649 2018-05-20 14:22:05 p2.dem
-rw-r--r-- idest/197609 5493525 2018-05-20 16:22:01 p3.dem
-rw-r--r-- idest/197609 6221390 2018-05-20 23:22:06 p4.dem
```

### Video Channel Information
Simple. The final video stream is encoded via `libx265` with `pix_fmt` set to
`yuv420p10le` and a `crf` of 17.

### Audio Channel Information
The final MKV will have ***5 Audio Streams***. One combining all 4 player audio
files, and one for each player. As of now, the names for the audio tracks are
hardcoded to be the names of the players in my personal run of Synergy, but it
can easily be tweaked in `encode.sh`.

Here's the information from FFmpeg about how the audio streams will be encoded:
```
    Stream #0:1: Audio: flac ([172][241][0][0] / 0xF1AC), 48000 Hz, 7.1, s32 (24 bit), 128 kb/s
    Metadata:
      title           : Game Audio - All
      encoder         : Lavc58.82.100 flac
    Stream #0:2: Audio: flac ([172][241][0][0] / 0xF1AC), 48000 Hz, 7.1, s32 (24 bit), 128 kb/s
    Metadata:
      title           : Game Audio - DKK
      encoder         : Lavc58.82.100 flac
    Stream #0:3: Audio: flac ([172][241][0][0] / 0xF1AC), 48000 Hz, 7.1, s32 (24 bit), 128 kb/s
    Metadata:
      title           : Game Audio - SKK
      encoder         : Lavc58.82.100 flac
    Stream #0:4: Audio: flac ([172][241][0][0] / 0xF1AC), 48000 Hz, 7.1, s32 (24 bit), 128 kb/s
    Metadata:
      title           : Game Audio - D4
      encoder         : Lavc58.82.100 flac
    Stream #0:5: Audio: flac ([172][241][0][0] / 0xF1AC), 48000 Hz, 7.1, s32 (24 bit), 128 kb/s
    Metadata:
      title           : Game Audio - Django
      encoder         : Lavc58.82.100 flac
```

#### True 7.0 Surround Sound
The `audio.flac` file in each player's directory may be modified to have more
audio channels than 2 (Stereo). Source Engine usually goes up to 5.0, but true
7.0 can be forced by using [IndirectSound](https://www.indirectsound.com/) to
restore DirectSound3D functionality. Afterwards, in Synergy, open up the
console and type `snd_legacy_surround 1`. Then, enable `7.1 Speakers` in the
audio settings. The LFE channel is silent. Bummer. 7.1 would've been nice.

![Waveforms in Audacity](https://github.com/iDestyKK/render_tools/blob/assets/synergy/7.0_waveform.png)
