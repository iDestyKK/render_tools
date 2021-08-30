# GeForce Experience Gameplay Muxing Tools via FFmpeg

## Synopsis
FFmpeg-powered remuxing tools for footage recorded via GeForce Experience. This
is similar to `gameplay` and `hdr_gameplay` branches, except the video is not
compressed via `libx264` or `libx265`. Instead, it is just a fancy remuxing
script that stream copies the video and supplementary audio files together into
a single MKV file. This is because GeForce Experience has the GPU encode the
video prior to this script needing to be run. So we can skip that step and
export desired MKV files in the same format as every other branch in this repo.

## Usage/Parameters
```bash
UNIX> ./prepare.sh
UNIX> ./remux.sh
```

## Additional Audio Tracks
See [this section in hdr\_gameplay](https://github.com/iDestyKK/render_tools/tree/dev/hdr_gameplay/hdr_gameplay#additional-audio-tracks)
regarding how additional audio tracks are handled. It's the exact same
procedure here. 16 Channel Mode (Dolby Atmos 7.1.4.4) is also handled the same
way.

### Preparing audio files
There is a script, `prepare.sh` which will extract audio from GeForce
Experience mp4 files. The first track, `gameplay stX (Game Audio).aac`, will be
the gameplay audio, and the second one, `gameplay st0 (Voice - Game).aac`, will
be microphone audio. If you recorded gameplay audio losslessly in an
application like [Audacity](https://www.audacityteam.org/), you can use
`gameplay stX (Game Audio).aac` to align and export lossless audio for your
gameplay clip. It sure beats using the AAC compressed audio GeForce Experience
gives you... just saying.

### Slight differences
I lied. There are a handful of differences compared to `hdr_gameplay`. This
script has **codec-agnostic** behaviour toward voice tracks. As such,
it doesn't just scan for `wav` or `flac` specifically. Instead, it will accept
any format. If a `wav` file is supplied, it will be compressed to `flac` when
muxing into the final MKV file.

As an example, this is perfectly valid:
```
gameplay.mp4
gameplay st0 (TRACK_NAME).aac
gameplay st1 (TRACK_NAME).wav
gameplay st2 (TRACK_NAME).flac
gameplay st3 (TRACK_NAME).mp3
```
It will compress `gameplay st1 (TRACK_NAME).wav` into `flac`. It will stream
copy every other track to preserve their original states.

## JSON file containing metadata
After the initial remux step, `gen_json.sh` will be auto-run, generating a
`info.json` file that contains all information about the MKV file. It will also
store amplification information used to boost the sound of the generated 7.1
surround sound track (if it was generated from a 16 channel file).

An example of the first few (23) lines is:
```json
{
	"filename": "Call of Duty  Black Ops Cold War 2021.08.29 - 17.38.09.01.mkv",
	"metadata": {
		"title": {
			"en-gb": "",
			"ja-jp": ""
		},
		"id": "",
		"rating": -1,
		"identifier": [],
		"comment": "",
		"amplify": 16.2
	},
	"date": {
		"recorded": {
			"iso-8601": "2021-08-29T17:38:11.594421600-04:00",
			"unix": 1630273091594421600
		},
		"encoded": {
			"iso-8601": "2021-08-29T20:48:15.081003400-04:00",
			"unix": 1630284495081003400
		}
	},
```
Information such as stream data, file size, duration, etc are also stored in
that file. It is stored as an MKV attachment as such:
```
  Stream #0:5: Attachment: none
    Metadata:
      filename        : info.json
      mimetype        : application/json
      title           : MKV Information
      LAST_MODIFIED   : 2021-08-29T20:49:00.238419600-04:00
```
This kind of file storage is based on `patch_attachments.sh`, from the
`hdr_render` suite of scripts.
