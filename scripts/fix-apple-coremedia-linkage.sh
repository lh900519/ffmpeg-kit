#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <xcframework-root> [<xcframework-root> ...]" >&2
  exit 2
fi

shim='@rpath/libswiftCoreMedia.dylib'
core_media='/System/Library/Frameworks/CoreMedia.framework/CoreMedia'
rewritten=0

for root in "$@"; do
  if [[ ! -d "$root" ]]; then
    echo "XCFramework root does not exist: $root" >&2
    exit 1
  fi

  while IFS= read -r -d '' framework; do
    name="$(basename "$framework" .framework)"
    binary="$framework/$name"
    if [[ ! -e "$binary" ]]; then
      binary="$framework/Versions/A/$name"
    fi
    if [[ ! -e "$binary" ]]; then
      echo "Framework binary not found: $framework" >&2
      exit 1
    fi

    found=false
    architectures="$(lipo -archs "$binary")"
    for architecture in $architectures; do
      if otool -arch "$architecture" -L "$binary" | grep -Fq "$shim"; then
        found=true
      fi
    done

    if [[ "$found" == true ]]; then
      install_name_tool -change "$shim" "$core_media" "$binary"
      rewritten=$((rewritten + 1))
      echo "Rebound CoreMedia symbols: $binary"
    fi

    for architecture in $architectures; do
      if otool -arch "$architecture" -L "$binary" | grep -Fq "$shim"; then
        echo "Swift CoreMedia shim remains in $binary [$architecture]" >&2
        exit 1
      fi
      if nm -arch "$architecture" -m "$binary" 2>/dev/null | grep -Fq 'from libswiftCoreMedia'; then
        echo "Swift CoreMedia symbol imports remain in $binary [$architecture]" >&2
        exit 1
      fi
    done
  done < <(find "$root" -type d -name '*.framework' -print0)
done

echo "Verified Apple framework binaries; rebound $rewritten framework(s)."
