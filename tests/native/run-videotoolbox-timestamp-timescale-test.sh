#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FRAMEWORK_DIR="${ROOT}/flutter/flutter/macos/Frameworks/ffmpeg-kit-macos-min-gpl/libavutil.xcframework/macos-arm64_x86_64/libavutil.framework"
TEST_BINARY="$(mktemp "${TMPDIR:-/tmp}/videotoolbox-timestamp-test.XXXXXX")"
trap 'rm -f "${TEST_BINARY}"' EXIT

clang "${ROOT}/tests/native/videotoolbox_timestamp_timescale_test.c" \
  -F "${FRAMEWORK_DIR}/.." \
  -framework CoreMedia \
  -framework libavutil \
  -Wl,-rpath,"${FRAMEWORK_DIR}/Versions/A" \
  -o "${TEST_BINARY}"

DYLD_FRAMEWORK_PATH="${FRAMEWORK_DIR}/.." "${TEST_BINARY}"
