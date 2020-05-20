::
:: GBA Automated Rendering via ffmpeg (x264 ver.)
::
:: Description:
::     Make a list file that contains your AVI files (or many list files, for
::     multiple videos in a "queue") and this script will render them all out
::     using libx264 compression. It will throw the files into a directory
::     named "processed", so make sure that's created before running the
::     script.
::
:: Author:
::     Clara Nguyen (@iDestyKK)
::

setlocal enabledelayedexpansion
for %%i in (*.txt) do ( call :Render "%%i" )
goto End

:Render
set fn=%1
set fn=%fn:"=%
ffmpeg -f concat -safe 0 -i "%fn%" -i "audio/%fn:txt=wav%" -strict -2 -pix_fmt yuvj420p -vcodec libx264 -b:v 12000k -maxrate 12000k -bufsize 12000k -acodec aac -s 1620x1080 -sws_flags neighbor -map 0:v:0 -map 1:a:0 -f mp4 "processed/%fn:txt=mp4%"

:End