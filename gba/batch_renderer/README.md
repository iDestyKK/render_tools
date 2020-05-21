# Batch GBA Gameplay Video Rendering via FFMPEG

## Synopsis
FFMPEG-powered batch renderer for GBA footage exported via VBA-RR. This is just
like `gameplay` except it accounts for the splitting of AVI files exported by
VBA-RR. Other than that, same deal. Takes files in `queue` and renders it.
These files are stored in the `processed` directory as MKV files.

Videos encoded via this script have the following specs:
* Matroska container (MKV)
* 1620x1080 resolution at 60 fps
* CRF 17
* FLAC encoded audio (`-compression_level 12`)
* pix\_fmt: `yuv420p10le`
* Original encoding directory compressed via tar+xz (Optional)

## Usage/Parameters
```
UNIX> ./render.sh -h
Usage: ./render.sh [-ahv]
...
```
You may pass parameters in as you run the script to change how it runs.
```
  -a  ARCHIVE
      Compresses a video's directory into a tar.xz file (XZ via `-9e`) and
      includes it as an attachment in the final MKV file.

  -h  HELP
      Prints out a help prompt and kills the script after.

  -v  VERBOSE
      Prints out extra information.
```

## Queue format
Unlike `gameplay`, files in the queue here must follow a semi-strict format.
There are two modes. I'll go over the format for both of them in **Mode 1:
Simple** and **Mode 2: Double Concat** sections below.

Each video's files will be stored in their own directories in `queue`. As such,
if you want a video called "test.mkv" in `processed`, your files to be encoded
will be stored in `queue/test`. The format for these directories is dictated by
two modes. The mode is determined automatically. You don't do any specifying.

### Mode 1: Simple
Let's take a look at `queue/test` assuming the simple layout. This is chosen
when `queue/test` has no directories in it. In this mode, simply store your
WAV file and all AVI files in. **There is no requirement on filename as long
as WAV files end in `.wav` and AVI files end in `.avi`.**
```
queue/
    test/
        audio.wav
        video.avi
        video_part2.avi
        video_part3.avi
```
The script will go through, concatenate all AVI files together, and mux the
only WAV file in the directory to be the audio of the final MKV file. Simple.

**You must have only one WAV file in the video's directory. More will result in
the script terminating and detailing the error.**

### Mode 2: Double Concat
This mode is for if you have multiple parts that you want concatenated into a
single final MKV file (e.g. if you segmented a run into multiple replays but
want it in a single video). In this case, `queue/test` will have directories
for each segment you wish to render out.
```
queue/
    test/
        part1/
            audio.wav
            video.avi
            video_part2.avi
            video_part3.avi
        part2/
            audio.wav
            video.avi
            video_part2.avi
```
In this case, the script will generate a single MKV file with all videos
concatenated in order, and all audio files concatenated in order.

If that wasn't clear, the videos will be concatenated in this order:
```
part1/video.avi
part1/video_part2.avi
part1/video_part3.avi
part2/video.avi
part2/video_part2.avi
```

The audio files will be concatenated in this order:
```
part1/audio.wav
part2/audio.wav
```

**Each segment directory must only have one WAV file. More will result in the
script terminating and detailing the error.**

## Production Procedure
1. Record your movie in VBA with the "Record New Movie" option. When you are
   done, click "Stop Movie".

2. Replay your movie back with "Play Movie". Make sure the game is paused
   before you begin. Make a new directory in `queue`. In VBA-RR, go to "Start
   AVI Recording" and record an AVI file to this new directory. Then, go to
   "Start WAV Recording" and have it record a WAV file to the new directory.
   Check the option "Pause at frame" and it'll fill in the last frame of the
   replay for you. **Don't change anything.** Once both are setup, unpause the
   emulator and let it record.

3. When it is done, simply run `./render.sh` and let it do the hard work for
   you. Your final MKV file will be placed in `processed`.

## Archival via `-a` option
In `gameplay`, the `-a` option was for amplification of audio. Here, it's
different... much more different.

So apparently AVI and WAV files exported raw compress extremely well via XZ. In
fact, an archive of the raw resources via this is around **0.0074x** its
original size (on average via testing a handful of clips...). Thus, it is
feasible to store the original files compressed into the final MKV as an
attachment. In fact, it's recommended. This way, if you ever need to go back to
the original files, you have an extra (somewhat esoteric) option.

Conveniently, I have made this an option to do automatically. Just tack on `-a`
in the command:
```
UNIX> ./render.sh -a
```
All MKV files created will then have their directories compressed and attached
as shown here:
```
Stream #0:2: Attachment: none
Metadata:
  filename        : master.tar.xz
  mimetype        : application/x-gtar
```
Not bad huh?
