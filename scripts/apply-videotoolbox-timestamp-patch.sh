#!/bin/bash

set -euo pipefail

BASEDIR="${BASEDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
FFMPEG_SOURCE="${BASEDIR}/src/ffmpeg"
PATCH_FILE="${BASEDIR}/patches/videotoolbox-timestamp-timescale.patch"

if [[ ! -f "${FFMPEG_SOURCE}/libavcodec/videotoolboxenc.c" ]]; then
  echo "FFmpeg VideoToolbox source not found at ${FFMPEG_SOURCE}" >&2
  exit 1
fi

if git -C "${FFMPEG_SOURCE}" apply --check "${PATCH_FILE}" 2>/dev/null; then
  git -C "${FFMPEG_SOURCE}" apply --whitespace=error "${PATCH_FILE}"
  echo "Applied VideoToolbox timestamp-timescale patch"
elif git -C "${FFMPEG_SOURCE}" apply --reverse --check "${PATCH_FILE}" 2>/dev/null; then
  echo "VideoToolbox timestamp-timescale patch is already applied"
else
  echo "FFmpeg source is incompatible with ${PATCH_FILE}" >&2
  exit 1
fi
