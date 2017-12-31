# GBA Tools (VBA & VBA-RR scripts)

## Synopsis
A handful of scripts for dealing with footage exported from the
VisualBoyAdvance emulator. These are written to work on Windows and rely either
on `ffmpeg` being a valid command or `ffmpeg.exe` existing in the same
directory as the script.

## Details
The following tools are available:

### fix\_vba\_sync.bat
```cmd
fix_vba_sync.bat INPUT.avi OUTPUT.avi
```
Speeds up the audio in `INPUT.avi` by 1.00551357x to align it with the video
track.

VBA has a bug where the video and audio streams are slightly misaligned. This
isn't noticeable in very short videos. When footage is around 5 minutes long or
more, though, the difference can be heard very easily. Speeding up the audio
1.00551357x fixes this (which is what this script does). Alternatively, you may
adjust the framerate to 59.671 FPS. This is not recommended. **This bug is
fixed in VBA-RR.**

### gba\_render.bat & gba\_render\_x265.bat
```cmd
gba_render.bat
```
or
```cmd
gba_render_x265.bat
```
View the `README.md` in the `batch_renderer` directory for details.
