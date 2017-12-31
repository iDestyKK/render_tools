# GBA footage batch renderer

### Usage
```cmd
gba_render.bat
```
or
```cmd
gba_render_x265.bat
```
The script scans the directory for TXT files and renders based on the
information in those, not the video files itself. So if you have multiple
videos you want rendered, make multiple text files.

The final video specs are:
* 1620x1080 resolution at 60 fps
* 12000k bitrate
* AAC encoded audio
* `yuvj420p` full colour video (if you use `gba_render.bat`)
* `yuv444p` 10-bit colour (if you use `gba_render_x265.bat`)

## Requirements
You MUST have `ffmpeg.exe` in the same directory as these scripts. You MUST
have the following structure for your folder:
```
audio/
processed/
ffmpeg.exe
gba_render.bat
gba_render_x265.bat
```
*A "/" at the end of a name means it's a folder.*

Furthermore, you must have all of your AVIs in the folder, and a list TXT file.
Here's an example of the directory structure:
```
audio/
    07 - Internet Exploration 1.wav
processed/
07 - Internet Exploration 1.avi
07 - Internet Exploration 1_part2.avi
07 - Internet Exploration 1_part3.avi
07 - Internet Exploration 1_part4.avi
07 - Internet Exploration 1_part5.avi
07 - Internet Exploration 1_part6.avi
07 - Internet Exploration 1.txt
ffmpeg.exe
gba_render.bat
gba_render_x265.bat
```

The `07 - Internet Exploration 1.txt` list file is a standard FFmpeg
concatenation-formatted file as follows:
```
file '07 - Internet Exploration 1.avi'
file '07 - Internet Exploration 1_part2.avi'
file '07 - Internet Exploration 1_part3.avi'
file '07 - Internet Exploration 1_part4.avi'
file '07 - Internet Exploration 1_part5.avi'
file '07 - Internet Exploration 1_part6.avi'
```

## Production Procedure
1. Record your movie in VBA with the "Record New Movie". When you are done,
   click "Stop Movie" (or whatever it is. it should be obvious).

2. Replay your movie back with "Play Movie". Make sure the game is paused when
   you begin. Then go to "Start AVI Recording", have it make the files in the
   same directory as the ffmpeg.exe file. Then go to "Start WAV Recording" and
   have it go to the `audio` directory specified above. Unpause the game and
   let it replay and record for you.

3. When it's done, make a list file (shown in the example above)... or list
   files (if you have multiple videos). Whatever you name the text file, your
   audio file MUST be the same name, except the `avi` must be changed to `wav`
   (e.g. If the list is named `07 - Internet Exploration.txt`, the audio file
   must be named `07 - Internet Exploration.wav`).

4. Run either `gba_render.bat` or `gba_render_x265.bat`. Let it sit and make
   your MP4 files, which will be in the `processed` directory when it is done
   (make sure this folder exists BEFORE running the script)
