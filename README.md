# Rendering Scripts

## Synopsis
Collection of rendering scripts that I use to automate content creation via
ffmpeg. This is done for archival purposes of gameplay footage. It is also
so I can access all of these scripts in one place (Since apparently I keep
losing them...).

## Renderers
Each directory has a "system" of rendering tools with very specific usages.
They are all powered by FFmpeg. Their development branch is also listed below.
If I haven't made the tools/scripts for a section public yet, the
**Dev Branch** will show as `n/a`.

| Name               | Dev Branch         | Description |
| ------------------ | ------------------ | --- |
| gameplay           | dev/gameplay       | AVI-\>MKV for Dxtory and Fraps footage |
| gba                | dev/gba            | AVI-\>MKV for recordings exported from VBA-RR. |
| half-life          | n/a                | Scripts for dealing with Half-Life 1 footage. Christmas Deathmatch scripts and some assets included. |
| hdr\_gameplay      | dev/hdr\_gameplay  | AVI-\>MKV for Dxtory footage recorded on an HDR display. Supplies a program to aid in generating HDR metadata for a delivery MKV file. |
| source-tga         | n/a                | TGA Frames-\>MKV for recordings exported from Source Engine games. |
| spyhunter          | dev/spyhunter      | Workspace for 4K SpyHunter (PS2 Reboot) gameplay project for DERPGProductions on YouTube. All scripts, and some assets are included. No video or audio files though. |
| synergy            | n/a                | Scripts for dealing with Synergy (HL2 Co-op Mod) Gameplay. Quad POV. 2x2 split-screen. |

## Setup
Each of these have their own specific setup requirements. But I try to make
it so that you only need to have `ffmpeg` as a valid command to run any shell
script. If this is not the case, I will document it in each renderer's
respective directory.
