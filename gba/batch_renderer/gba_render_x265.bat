::
:: GBA Automated Rendering via ffmpeg (x265 ver.)
::
:: Description:
::     Make a list file that contains your AVI files (or many list files, for
::     multiple videos in a "queue") and this script will render them all out
::     using libx265 compression. It will throw the files into a directory
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
ffmpeg -f concat -safe 0 -i "%fn%" -i "audio/%fn:txt=wav%" -strict -2 -acodec ac3 -s 1620x1080 -sws_flags neighbor -strict -2 -pix_fmt yuv444p -vcodec libx265 -vf "fps=60,scale=out_color_matrix=bt2020:out_color_matrix=bt2020" -x265-params "input-depth=10:crf=23:colorprim=bt2020:transfer=bt2020-10:colormatrix=bt2020nc" -map 0:v:0 -map 1:a:0 -shortest "processed/%fn:txt=mp4%"

:End