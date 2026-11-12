# Apple framework rebuild, replacement, and rollback

This is the reproducible procedure for the min-gpl Apple libraries. A complete clean build has not yet been run, so treat the commands as the recorded build configuration pending Xcode compatibility verification.

## Pinned inputs and tools

- FFmpegKit checkout: `624081e176058976f2f31d05e3882ba87a22f932` (`624081e`).
- FFmpeg source selector: `arthenica/FFmpeg` tag `n6.0`, checked out as `ea3d24bbe3c58b171e55fe2151fc7ffaca3ab3d2` in this session.
- Timestamp patch: `patches/videotoolbox-timestamp-timescale.patch`, SHA-256 `0cbd7b5370bf62ebf2bb91b431ed22ef41ef9c8da42379d77a4228f7ac08b51c`.
- Toolchain observed: Xcode 27.2 / build 27B48, iOS SDK 27.2, macOS SDK 27.2.
- Build tools required by the scripts: Xcode command-line tools (`xcrun`, `xcodebuild`, Clang, `lipo`, `install_name_tool`), Git, curl, make, patch, Autoconf/Automake, CMake, pkg-config, and NASM for x264. `nasm` and `automake` were absent from `PATH` at baseline.

## Build commands

Run from the root of the `ffmpeg-kit` checkout. These options explicitly keep the VideoToolbox hardware encoders and GPL x264/x265 software encoders enabled and ask for XCFramework bundles:

```sh
PATH=/opt/homebrew/bin:$PATH http_proxy=http://127.0.0.1:1087 https_proxy=http://127.0.0.1:1087 ./ios.sh --xcframework --enable-gpl --enable-ios-videotoolbox --enable-ios-audiotoolbox --enable-ios-avfoundation --enable-ios-bzip2 --enable-ios-zlib --enable-ios-libiconv --enable-x264 --enable-x265 --enable-xvidcore --enable-libvidstab
PATH=/opt/homebrew/bin:$PATH http_proxy=http://127.0.0.1:1087 https_proxy=http://127.0.0.1:1087 ./macos.sh --xcframework --enable-gpl --enable-macos-videotoolbox --enable-macos-audiotoolbox --enable-macos-avfoundation --enable-macos-bzip2 --enable-macos-zlib --enable-macos-libiconv --enable-macos-coreimage --enable-macos-opencl --enable-macos-opengl --enable-x264 --enable-x265 --enable-xvidcore --enable-libvidstab
```

The common source-download function applies the timestamp patch after obtaining FFmpeg. The expected output roots are `prebuilt/bundle-apple-xcframework-ios/` and `prebuilt/bundle-apple-xcframework-macos/`.

With Xcode 27.2, run `scripts/fix-apple-coremedia-linkage.sh` on both generated XCFramework roots before replacing the plugin bundles. It rewrites `@rpath/libswiftCoreMedia.dylib` dependencies to the C `CoreMedia` framework and verifies every architecture slice. Without this step, iOS 18.5 can fail during launch before Dart starts.

## Build and validation record

- Build date: 2026-11-12.
- iOS command: the command above — succeeded. `Info.plist` lists arm64/arm64e device, arm64/x86_64 simulator, and arm64/x86_64 Mac Catalyst slices in all eight frameworks.
- macOS command: the command above — succeeded. All eight frameworks contain arm64 and x86_64.
- Compared the embedded FFmpeg configure strings from the prior bundles with the rebuilt bundles: all enabled/disabled options now match. The build script removes Xvid 1.3.7's legacy `typedef int bool` before compiling its C sources in the Apple C++11 mode. Xvid (`libxvid`) and vid.stab (`vidstabdetect`/`vidstabtransform`) are present in the rebuilt binaries.
- External sources: Xvid `release-1_3_7` at `d7eeb1a838fb403123711d63acc0430aa3d9edf9`; vid.stab `v1.1.1` at `90c76aca2cb06c3ff6f7476a7cd6851b39436656`.
- `lipo -archs` confirmed the device `libavcodec` is arm64/arm64e and the macOS universal `libavcodec` is x86_64/arm64. `otool -L` showed the expected VideoToolbox, CoreMedia, CoreVideo, CoreFoundation, libc++, and FFmpeg framework dependencies.
- `strings` on both built `libavcodec` binaries found `libx264`, `libx265`, `h264_videotoolbox`, and `hevc_videotoolbox`.
- The built complete eight-framework sets were copied into the Flutter plugin's iOS and macOS `Frameworks` directories after saving the original directories to `/private/tmp/ffmpeg-kit-apple-frameworks-backup-20261112`. Intermediate builds were saved separately under `/private/tmp/ffmpeg-kit-partial-frameworks-20261112` and `/private/tmp/ffmpeg-kit-apple-frameworks-pre-xvid-vidstab-20261112`.
- SHA-256 values for every XCFramework binary slice are recorded in `artifact-sha256.txt`.
- App integration: temporarily changed `superassistant` to `path: ../ffmpeg-kit/flutter/flutter`, ran `flutter pub get`, and ran `flutter build ios --simulator --no-codesign` successfully. `.dart_tool/package_config.json` resolved the plugin to `../../ffmpeg-kit/flutter/flutter`; the built app's `libavcodec.framework/libavcodec` was arm64/x86_64 and SHA-256 `b6f8a77b2356f8f4428ab45fef635d51baae5ac49fd9e1fb5a2fbf5a7103f3c1`, matching the rebuilt simulator slice. The original Git dependency and lockfile have since been restored.

### Validation procedure

For each platform, require exactly the eight frameworks already used by the plugin: `ffmpegkit`, `libavdevice`, `libavcodec`, `libavfilter`, `libavformat`, `libavutil`, `libswresample`, and `libswscale`.

- Compare each XCFramework `Info.plist` with the baseline: iOS device arm64, simulator arm64/x86_64, Catalyst arm64/x86_64; macOS arm64/x86_64.
- Run `lipo -archs` for each framework binary and `otool -L` to inspect architecture and linked system libraries.
- Confirm `libx264`, `libx265`, `h264_videotoolbox`, and `hevc_videotoolbox` are registered in the built codecs. Validate that VideoToolbox output from an actual Apple device has reasonable PTS deltas and duration.
- Record the source revisions, patch SHA-256, Xcode and SDK versions, full commands, architecture lists, encoder checks, and SHA-256 for every replaced framework binary.

## Replacement and rollback

After both builds and validations pass, copy the complete `prebuilt/bundle-apple-xcframework-ios/` and `prebuilt/bundle-apple-xcframework-macos/` output sets into the plugin's iOS and macOS `Frameworks/ffmpeg-kit-*-min-gpl/` directories. Replace the full eight-framework directory for each platform so simulator and Catalyst slices cannot be dropped. Before replacement, save both existing directories outside the checkout. To roll back, restore those saved directories wholesale and rerun the framework/archive checks.

The application remains on its pinned Git dependency until the rebuilt artifacts have been delivered in a fixed fork commit or tag. A local `path:` dependency is only for app integration validation.

## Current validation state

The patch application and timestamp arithmetic checks, iOS/macOS builds, CoreMedia linkage normalization, framework replacement, architecture checks, configure-option parity, Xvid/vid.stab and other encoder checks, refreshed artifact hashes, isolated plugin-host iOS archive, and synthetic iPhone SE3 integration matrix are complete. The isolated archive's app bundle passed ad-hoc signature verification; this is not distribution signing. The full app archive remains blocked by the unrelated `in_app_purchase_storekit` duplicate-enumerator compile error documented in `flutter-validation.md`. The physical-device results validate the synthetic matrix only and do not prove the reported production sample was reproduced or fixed.
