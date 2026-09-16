#!/bin/bash
# Builds and runs the macOS face-alignment harness over private portraits.
# The iOS simulators on this Mac cannot create a Vision inference context, so real-face evidence
# comes from macOS Vision (same Swift API) until physical-device runs are set up.
#
# Usage: scripts/face-harness.sh [pictures folder] [output folder]
# Defaults: <repo>/pics and <repo>/Artifacts/face-report (both git-ignored).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
pictures="${1:-$repo_root/pics}"
output="${2:-$repo_root/Artifacts/face-report}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

mkdir -p "$repo_root/build"
xcrun --sdk macosx swiftc -O -swift-version 6 -strict-concurrency=complete \
  -target arm64-apple-macos26.0 \
  -framework Vision -framework CoreImage \
  "$repo_root/Spikes/IDPhotoSpike/App/Domain/PhotoGeometry.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Domain/FaceGeometry.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Domain/Background.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Domain/Tone.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Imaging/FaceAnalyzer.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Imaging/BackgroundSegmenter.swift" \
  "$repo_root/Spikes/IDPhotoSpike/App/Imaging/ToneAdjuster.swift" \
  "$repo_root/scripts/face-harness/main.swift" \
  -o "$repo_root/build/face-harness"

exec "$repo_root/build/face-harness" "$pictures" "$output"
