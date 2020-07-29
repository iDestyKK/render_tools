# Utils

## Synopsis
Simple utility programs and scripts which are utilised by some of the other
tools featured in the repo. All placed in one spot here for convenience.

Here, there's a Windows binary for FFmpeg which is currently being used for
all encoding jobs on Windows. For Linux systems, some scripts are able to
detect that `ffmpeg` is a command and use that instead. If it isn't a valid
command, it will try to run the `ffmpeg.exe` in this current directory.

## Non-shell utilities (C/C++/other)
The `src` directory contains source code for applications written in languages
that aren't bash. Usually I resort to C or C++ whenever it's easier to write a
tool in those languages as opposed to bash.

All of the tools in `src` have their own subdirectory, complete with a makefile
that can be used to compile each program.

## Shell Scripts
In this directory, there's bash scripts. Here's descriptions for them:

### gen\_json.sh
```bash
UNIX> ./gen_json.sh filename
```
When given a video file at `filename`, this prints out a valid JSON file
containing information about it. The information given includes:

* Filename at the time of the script running
* Metadata
  * Title
  * Rating
  * Identifiers/Tags
  * Comment
  * Amplify (If amplification via `agrep` is utilised)
* Video duration in both **timestamp** and in **seconds**.
* Size of file
* Stream information
  * Video Stream: resolution, codec, pix\_fmt, fps
  * Audio Stream: codec, sample_rate, channel format
