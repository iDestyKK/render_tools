# MAME Gameplay and Recording Scripts

## Synposis

Collection of scripts for dealing with playing on MAME. These scripts aim to
allow replay of gameplay, as well as video generation and video uploading. For
archival, recording of multitrack audio (Game and Microphone) is performed and
synced automatically so no editing in post is required.

## Running ROMs

On Linux, this series of scripts assumes the following:

* MAME directory is located at `~/.mame`.
* Inputs recorded are at `~/.mame/inp`.
* MAME is properly configured (e.g. You are able to run a ROM via `mame ROM_NAME`).

To run a ROM, instead of doing `mame ROM_NAME`, do
`./run_rom_w_mic.sh ROM_NAME`. It will record and then generate a TAR.XZ file
containing the recorded inputs, as well as some additional information.

## Session Recording Information

After playing a session, a TAR.XZ file is created that contains some files. The
file will be named with the timestamp of when the session was recorded, as well
as the ROM name (e.g. `[2024-11-01 - 16 48 34] area88.tar.xz`).

### File information

In the file is 3 files: inputs.inp, info.json, stems.mka. For `inputs.inp`, it
simply contains the button and joystick inputs for the session and can be
played back in MAME. When this file is played back, it can be combined with
`-aviwrite FILE` to generate a video to upload to YouTube.

For `stems.mka`, it stores 2 audio tracks. One is the recorded game audio. The
other is a microphone feed. This allows for archiving our voice reactions while
playing. Given the tracks are separated, they can be edited in post for
content-creation purposes. It should be noted, more audio tracks and
microphones can be added in by modifying `run_rom_w_mic.sh`.


For `info.json`, it contains the MAME version, ROM name, and timestamps of the
exact moments the replay and `stems.mka` file were created. Here's a sample
file as an example:

```json
{
	"mame_ver": "0.269 (mame0269-dirty)",
	"rom": "area88",
	"timestamp": {
		"MAME": "2024-11-01T16:48:36.739578316-04:00",
		"AUDIO": "2024-11-01T16:48:34.784636410-04:00"
	}
}
```

Storing the ROM name allows playing back the file without the user having to
specify the ROM name manually. The timestamps allow for better
synchronisation between `stems.mka` and an exported
