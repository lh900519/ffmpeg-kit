# VideoToolbox timestamp fix baseline

Baseline captured on 2026-11-12 before implementation changes.

## Repository state

### ffmpeg-kit

- Branch: `min_gpl`, tracking `origin/min_gpl`.
- The worktree contains five staged OpenSpec planning files for this change. No unstaged changes were present at baseline capture.
- The planning files are retained unchanged.

### superassistant

- Location: `../superassistant`, branch `feat_superassistant`, initially one commit ahead of `origin/feat_superassistant`.
- At initial capture, `.gitignore` and six Dart files had user changes. A later status check found the worktree clean at the same HEAD; later during this session the user added unrelated image-remake duration changes and an OpenSpec change. Those files have been preserved.
- The app uses the Git dependency `https://github.com/lh900519/ffmpeg-kit.git`; `path: ../ffmpeg-kit/flutter/flutter` is commented out. The path was used only for the integration validation described in `apple-build.md` and then restored.

## Existing cut call sites

1. `lib/modules/creation/video/show_create_pro/logic.dart`
2. `lib/modules/creation/video/image_ai_remake/logic.dart`
3. `lib/modules/creation/video/lip_sync/create_custom/logic.dart`
4. `lib/modules/creation/video/oral/create_video/logic.dart`

## Access constraint

The active OpenSpec action context allows edits only under this `ffmpeg-kit` repository. The sibling `superassistant` worktree was inspected read-only; its pre-existing changes were not modified.

## Apple binary baseline

- FFmpegKit source revision: `624081e176058976f2f31d05e3882ba87a22f932` (`624081e`). `scripts/source.sh` selects the `arthenica/FFmpeg` `n6.0` tag. The ignored `src/` directory contains no downloaded source at baseline.
- Both iOS and macOS plugin bundles contain the same eight frameworks: `ffmpegkit`, `libavdevice`, `libavcodec`, `libavfilter`, `libavformat`, `libavutil`, `libswresample`, and `libswscale`.
- iOS XCFramework slices: device arm64; simulator arm64 and x86_64; Mac Catalyst arm64 and x86_64.
- macOS XCFramework slices: arm64 and x86_64.
- The existing iOS and macOS `libavcodec` binaries contain `libx264` and `libx265` references. The Apple build scripts expose VideoToolbox, x264, and x265 switches; `scripts/apple/ffmpeg-kit.sh` adds `--enable-videotoolbox` when the platform option is enabled, and GPL builds require `--enable-gpl`.
- The old binaries' embedded FFmpeg configure strings also enabled zlib, bzip2, iconv, AudioToolbox, and AVFoundation; macOS additionally enabled CoreImage, OpenCL, and OpenGL. Both old bundles enabled `libxvid` and `libvidstab`; the rebuilt configuration now matches these options and includes both libraries.
- CocoaPods min-gpl-local subspecs vend all eight frameworks. The Apple build helper links `-lc++`; FFmpegKit's framework link flags include Foundation and CoreVideo. The source includes VideoToolbox, CoreVideo, and CoreMedia headers.
- Toolchain observed: Xcode 27.2 (build 27B48), iOS SDK 27.2, macOS SDK 27.2, CMake, Autoconf, libtool, Git, patch, and SHA-256 tools. Homebrew `automake`, `nasm`, and arm64 `pkgconf` were installed for the native builds. The pre-existing `/usr/local/bin/pkg-config` was an incompatible x86 binary, so builds used `PATH=/opt/homebrew/bin:$PATH`.
- Clean iOS and macOS XCFramework builds were run successfully with the commands recorded in `apple-build.md`; this verifies this checkout's compatibility with Xcode 27.2.
- Baseline example hash: iOS arm64 `libavcodec` SHA-256 `e33aaf819e226147f65635179a2c6ca3ad6185b69e55d974385e3bbc6b93f289`; macOS universal `libavcodec` SHA-256 `ef95d8a2e5a331efeea37067588ac26d5ee1df310d87f51326a44c8fa56f86`.
