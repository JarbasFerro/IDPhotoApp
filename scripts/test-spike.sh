#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo 'Usage: scripts/test-spike.sh "platform=iOS Simulator,id=<simulator UUID>"' >&2
  echo 'List available simulators with: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

exec xcodebuild \
  -project Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj \
  -scheme IDPhotoSpike \
  -destination "$1" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO test
