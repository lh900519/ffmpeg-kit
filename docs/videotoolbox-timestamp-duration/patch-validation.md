# FFmpeg VideoToolbox patch validation

## Source and patch identity

- Source repository: `https://github.com/arthenica/FFmpeg.git`
- Pinned selector in `scripts/source.sh`: tag `n6.0`
- Checked-out commit: `ea3d24bbe3c58b171e55fe2151fc7ffaca3ab3d2`
- Patch: `patches/videotoolbox-timestamp-timescale.patch`
- Patch SHA-256: `0cbd7b5370bf62ebf2bb91b431ed22ef41ef9c8da42379d77a4228f7ac08b51c`

The patch rejects invalid PTS, converts PTS and DTS independently from each `CMTime.timescale` to `AVCodecContext.time_base` with `av_rescale_q`, and retains the existing missing-DTS fallback and `dts_delta` adjustment.

## Build-flow application

`downloaded_library_sources()` now applies the patch immediately after the FFmpeg source download. `scripts/apply-videotoolbox-timestamp-patch.sh` accepts a source only if the patch applies cleanly or its reverse applies cleanly; an already-patched source is left alone, and an incompatible source exits with an error. This keeps the change reproducible even though `src/` is ignored.

## Checks run

- Cloned the pinned `n6.0` source into the ignored `src/ffmpeg` directory, ran the application script, and confirmed the source diff contains only the intended timestamp change.
- Ran the application script again and confirmed it reports the patch already applied.
- Ran the script against a temporary source fixture with a changed hunk and confirmed it exits nonzero.
- Ran `git diff --check` against both the patch and patched FFmpeg source.
- Ran `tests/native/run-videotoolbox-timestamp-timescale-test.sh`. Native CoreMedia cases passed for `1/30` seconds at an unchanged 1/30 timescale, `33333/1000000` seconds converted to one 1/30-second tick, and invalid PTS rejection. The test links the current macOS `libavutil` framework to exercise `av_rescale_q`.

The patched FFmpeg source was compiled in successful iOS and macOS XCFramework builds on Xcode 27.2. Full framework build and hash results are recorded in `apple-build.md` and `artifact-sha256.txt`.
