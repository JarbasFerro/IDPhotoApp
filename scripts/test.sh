#!/bin/bash
# Runs the Calipic tests on an iPhone simulator.
#   scripts/test.sh auto                                   every test, on the first available iOS 27 iPhone
#   scripts/test.sh --unit auto                            the Swift Testing suite only (what CI runs)
#   scripts/test.sh 'platform=iOS Simulator,id=<UUID>'     a specific simulator
set -euo pipefail

only=()
if [[ "${1:-}" == "--unit" ]]; then only=(-only-testing:CalipicTests); shift; fi
if [[ $# -ne 1 ]]; then
  echo 'Usage: scripts/test.sh [--unit] auto|"platform=iOS Simulator,id=<simulator UUID>"' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
# Keep a DEVELOPER_DIR the caller chose (CI selects its Xcode); otherwise use the installed Xcode.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

destination="$1"
if [[ "$destination" == "auto" ]]; then
  id=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if ".iOS-" not in runtime or int(runtime.split(".iOS-")[1].split("-")[0]) < 27:
        continue
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"]); sys.exit()
')
  if [[ -z "$id" ]]; then echo "No iPhone simulator with iOS 27 or later is available." >&2; exit 1; fi
  destination="platform=iOS Simulator,id=$id"
fi
echo "Testing on: $destination"

exec xcodebuild \
  -project Calipic/Calipic.xcodeproj \
  -scheme Calipic \
  -destination "$destination" \
  -derivedDataPath build/DerivedData \
  ${only[@]+"${only[@]}"} \
  CODE_SIGNING_ALLOWED=NO test
