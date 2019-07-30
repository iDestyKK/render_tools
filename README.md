# Batch Gameplay Video Rendering via FFMPEG

## Synopsis
  FFMPEG-powered batch renderer for gameplay footage. Now that's how it's done.
  Takes AVI files in the "queue" directory and renders it. These files are
  stored in the "processed" directory as MKV files.

## Main
The renderer has 2 presets for rendering videos. These are based on how good
you want the quality of the final video to be:

* Regular - CRF 23 - Medium Speed (Average Size, Lower Quality )
* Bluray  - CRF 18 - Slow Speed   (Smaller Size, Higher Quality)

Videos that are already rendered will be skipped in future runs of the
script as long as they are present in the "processed" directory.

Codecs used are determined in the parameters, but the default is x265. The
pixel format is yuv420p10le, so the videos are being encoded in 10-bit to
optimise space as efficiently as possible.

## Parameters
You may pass parameters in as you run the script to change how it runs.
```
  -a --amp   AMPLIFY (NORMALISE)
             All videos encoded will be normalised to max volume. This will
             require FFMPEG scanning through each video file to find the
             loudest sound, which may take a while (This is recommended for
             surround sound clips).

  -4 --x264  X264 ENCODE
             All videos encoded will be encoded with the x264 codec. This is
             faster than x265 but will feature less compression. In a nutshell,
             you get faster encoding, with a larger file size and less quality.

  -5 --x265  X265 ENCODE
             All videos encoded will be encoded with the x265 codec. This is
             slower than x264 but will feature better compression. In a
             nutshell, you get slower encoding, with a smaller file size and
             better quality.
```

## Examples
Encode in x264
```bash
./avi_proc.sh -4
```

Encode in x265
```bash
./avi_proc.sh -5
```

Encode in x264 with volume normalising
```bash
./avi_proc.sh -4a
```

Encode in x265 with volume normalising
```bash
./avi_proc.sh -5a
```

## ADDITIONAL AUDIO TRACKS
By default, the script will only use the very first audio track in the AVI
file. However, if you have suppliment WAV files of similar names, the script
will append them into the final MKV file. They must follow a strict syntax:

```
gameplay.avi
gameplay st0 (TRACK_NAME).wav
gameplay st1 (TRACK_NAME).wav
gameplay st2 (TRACK_NAME).wav
```

"TRACK_NAME" is replaced with the name. So `gameplay st0 (Voice - DKK).wav`
is valid. When the final render is complete, open the MKV in VLC and the
tracks will be there.
