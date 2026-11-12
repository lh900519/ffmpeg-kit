# Flutter integration validation

## Dart checks

On 2026-11-12, ran:

- `flutter test test/unit/utils/video_edit_timestamp_integrity_test.dart test/unit/utils/video_upload_order_test.dart` — 14 tests passed. These use fake probes, command execution, file deletion, and upload callbacks; they do not invoke a real FFmpeg process, network uploader, or third-party SDK.
- `flutter analyze` on the 13 changed Dart files — no issues found.
- The upload-order tests cover a valid cut, hardware failure followed by successful software retry, total cut failure with source preservation and no upload, and the no-transcode rename/upload path. All four business call sites now use the same prepare/delete/upload coordinator.

## iOS simulator app integration

Temporarily changed `superassistant` to `path: ../ffmpeg-kit/flutter/flutter`, ran `flutter pub get`, and built with `flutter build ios --simulator --no-codesign`. The build succeeded with the final bundles, including Xvid and vid.stab, and all prior AudioToolbox, AVFoundation, zlib, bzip2, and iconv options. `package_config.json` resolved `ffmpeg_kit_flutter_min_gpl` to `../../ffmpeg-kit/flutter/flutter`, CocoaPods resolved `min-gpl-local`, and the resulting app's `libavcodec` was arm64/x86_64 with SHA-256 matching the rebuilt simulator slice (`6684b2b801311807f819e52d7be4887e71e230102e8cc0cada0a3b52a9723dc3`). The temporary path dependency and lockfile changes were restored afterward.

## Archive and device limits

An unsigned iOS device archive was attempted after synchronizing CocoaPods. It failed while compiling the app's existing `in_app_purchase_storekit` dependency: generated `messages.g.h` redeclares `FIASKProductDiscountPaymentModeMessagePayAsYouGo` and `FIASKProductDiscountPaymentModeMessagePayUpFront`. Retrying with explicit Swift modules disabled failed at the same dependency step. The failure is outside the FFmpeg plugin target; the simulator app build and all standalone framework builds succeeded. The connected device is an iPhone SE (3rd generation), iOS 18.5, and Flutter recognizes it. The isolated local-plugin harness compiled for the device, but install was rejected because its temporary bundle ID has no matching provisioning profile and Xcode reports no account configured for automatic signing. Two valid development identities and app-specific profiles exist locally; the existing `superassistant` profile is restricted to `com.chatai.super.test1`. Its current package config still resolves the old remote plugin commit `369244e916e58ad4090a235d8cf5f168836996fb`, so it does not exercise the rebuilt frameworks.

To isolate the plugin from that unrelated app dependency, a temporary Flutter host using the local path dependency was archived separately with Xcode 27.2: `/private/tmp/ffmpeg-kit-plugin-smoke-20261112.xcarchive`. The unsigned archive succeeded and contains all eight FFmpeg frameworks. Its embedded device `libavcodec` is arm64 and includes Xvid, x264, x265, and VideoToolbox encoders; `libavfilter` includes `vidstabdetect` and `vidstabtransform`. Applying an ad-hoc signature to the archived app and running `codesign --verify --deep --strict` succeeded (`valid on disk`, `satisfies its Designated Requirement`). This verifies the plugin archive and bundle signature structure; it is not an App Store distribution signature. The full `superassistant` archive remains blocked by the StoreKit duplicate-enumerator error above.

## iPhone SE (3rd generation), iOS 18.5

The device test used the existing `superassistant` bundle ID (`com.chatai.super.test1`) and its manual development profile; the Flutter package name and Bundle ID were not changed. The dependency was temporarily pointed at the local plugin, and the original `pubspec.yaml`, lockfiles, package config, and app entrypoint were restored after testing. The current `superassistant` package config again resolves the old pinned Git commit; the device evidence below is from the temporary local-plugin build.

The first install compiled but crashed before Dart startup because Xcode 27.2 linked several framework slices to `@rpath/libswiftCoreMedia.dylib`, which iOS 18.5 does not export for these C CoreMedia APIs. `scripts/fix-apple-coremedia-linkage.sh` now rebinds those imports to `CoreMedia.framework`. After rebuilding with that correction, the app launched and the following synthetic cases completed:

- CFR VideoToolbox, no audio: H.264, 4.000 s, 120 frames; 12 sampled PTS values had 33.333–33.334 ms intervals.
- VFR VideoToolbox, no audio: H.264, 3.983 s, 76 frames; sampled PTS intervals varied from 16.667 ms to 83.333 ms.
- Audio/video sync: H.264 video and AAC audio were each 4.000 s, with first packet PTS 0.000 s on both streams. Muted AVPlayer playback reached 3.892 s of 4.000 s before entering the final 150 ms playback window.
- Start trim: `-ss 0.7 -t 1.8` produced a 1.800 s video-only output with 54 frames.
- Software encoder availability: an intentionally invalid encoder failed with return code 1; a separate `libx264` encode succeeded with a 2.000 s, 60-frame output and 33.333–33.334 ms sampled intervals.

These synthetic measurements verify the rebuilt native bundle on this device and do not establish that the reported production sample was reproduced or fixed. No damaged production sample was available for device import rejection testing.
