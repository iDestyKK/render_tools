# Functional Rendering and Clip Generation

## Synopsis
Collection of rendering scripts to generate clip compilations. Some allow for
CSV input. Others use files with lines of function-like formatting to generate
videos.

I call this **Functional Rendering**. As in, I write functions to generate
portions of videos meant to be stitched together. If I wanted a photograph I
took shown with a blurry background, it can be done. If I wanted to jump-cut
several portions of the same video with start-end timestamps, consider it done.

In Functional Rendering, renders are done partially, can be resumed "per part",
and works on any device that you can put FFmpeg and Bash on. Also, the script
file is considered the "project file" for the video. A simple text file being a
project file is a nice convenience to some people.
