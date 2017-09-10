@echo off

if [%1]==[] goto usage
if [%2]==[] goto usage

:main
ffmpeg -hide_banner -i %1 -filter:a "atempo=1.00551357" -vcodec copy -acodec pcm_s16le -shortest %2
goto end

:usage
@echo Usage: fix_vba_sync.bat INPUT.avi OUTPUT.avi
goto end

:end
exit /b 0