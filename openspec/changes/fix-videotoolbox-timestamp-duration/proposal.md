## Why

线上极少数用户反馈十几秒视频被识别为上百小时。样本的视频 PTS 放大规律与旧版 FFmpeg VideoToolbox 忽略返回 CMTime.timescale 的换算缺陷高度吻合；当前流程仅按 FFmpeg 返回码判断成功，异常产物可能被直接上传。

## What Changes

- 在当前 `ffmpeg-kit` 仓库 的 `min_gpl` fork 中回移 VideoToolbox 时间戳换算修复，保存可重复应用的源码补丁和构建步骤。
- 重建 iOS/macOS 的完整 XCFramework 集合，保留当前 Flutter 包名、API、架构和 x264/x265 软件回退能力，记录源码版本及产物校验值。
- 在 `VideoEdit.cut()` 返回成功前校验输出视频时长；硬件编码返回失败或产物异常时，使用原始输入按同一裁剪参数进行至多一次软件重试。
- 在裁剪和时间轴入口保留并完善异常输入拦截；输出验证通过前不得上传或提前清理原始输入。
- 本地通过 path 依赖验收修复；发布接入使用包含修复后二进制的固定 Git 提交或标签，避免依赖开发者机器路径。

### Non-goals

- 不更换为其他 FFmpegKit 发行版，不升级 FFmpeg 大版本，不重构媒体业务架构。
- 不自动修复已损坏的视频，不根据猜测帧率为所有输入强制重建时间轴。
- 不修改 Android AAR、Windows FFmpeg 分发、路由、公开 Dart API、多语言或生成模型。

## Capabilities

### New Capabilities

- `video-transcode-timestamp-integrity`: Apple 视频编码时间戳正确性、可追溯原生构建、输出校验、有限软件回退与异常输入阻断。

### Modified Capabilities

无。现有主规格尚未定义 FFmpeg 视频轨时间戳完整性。

## Impact

- 跨仓库：`ffmpeg-kit` 仓库中补丁、Apple 构建脚本、插件版本和内置 iOS/macOS XCFramework；本项目依赖声明及锁文件。
- 运行时：`lib/utils/video_edit.dart` 和四处 `VideoEdit.cut()` 调用流程，以及已有五处异常输入检查。工作区已有未提交的拦截改动，实施时先核对并复用。
- 产物异常将触发软件重试或既有失败反馈，不再以返回码成功直接认定转码成功；正常视频沿用现有处理参数。
- 原生构建及受影响设备验证是交付要求；自动化业务测试使用 fake 隔离 FFmpeg、探测、文件和上传服务。
