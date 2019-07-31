# Rendering Scripts

## Synopsis
Collection of rendering scripts that I use to automate content creation via
ffmpeg. This is done for archival purposes of gameplay footage. It is also
so I can access all of these scripts in one place (Since apparently I keep
losing them...).

## Renderers
Each directory has a "system" of rendering tools with very specific usages.
They are all powered by FFMPEG.

* **gameplay** - AVI-\>MKV for Dxtory and Fraps footage.
* **gba** - AVI-\>MKV for recordings exported from VBA-RR.
* **source-tga** - TGA Frames-\>MKV for recordings exported from Source Engine games.

## Setup
Each of these have their own specific setup requirements. But I try to make
it so that you only need to have `ffmpeg` as a valid command to run any shell
script. If this is not the case, I will document it in each renderer's
respective directory.
