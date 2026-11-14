#!/bin/bash
# Runs the Calipic tests on an iPhone simulator.
#
# Two levels (2026-11-14): the unit tests after each change, the UI tests of the screens touched, and the full run
# (UI tests spread over cloned simulators) once before a commit.
#
#   scripts/test.sh auto                                   every test; UI tests on 3 simulator clones in parallel
#   scripts/test.sh --unit auto                            the Swift Testing suite only, about 15 s (what CI runs)
#   scripts/test.sh --ui testTutorialWelcomeAndHome,testSettingsLanguageMenu auto
#                                                          only these UI tests (comma-separated names)
#   scripts/test.sh 'platform=iOS Simulator,id=<UUID>'     a specific simulator
#
# Options, before the destination:
#   --workers N        simulator clones for the full run (default 3: 4 was no faster on a 10-core Mac; 1 = no clones)
#   --result NAME      keep the result bundle at build/NAME.xcresult (summary and screenshots: see docs/00-handoff.md)
#   --language CODE    run in another language, e.g. es or pt-BR (screenshots for a translation check)
#   --no-build         reuse the last build (after a build-for-testing or an earlier run)
set -euo pipefail

only=()
workers=3
result=()
language=()
action=test
while [[ $# -gt 1 ]]; do
  case "$1" in
    --unit) only=(-only-testing:CalipicTests); workers=1; shift ;;
    --ui)
      IFS=',' read -ra names <<< "$2"
      for name in "${names[@]}"; do
        # The class is the file that defines the test (one class per file in Calipic/UITests).
        file=$(grep -l "func $name(" "$(dirname "$0")"/../Calipic/UITests/*.swift | head -1)
        if [[ -z "$file" ]]; then echo "No UI test named $name." >&2; exit 2; fi
        only+=("-only-testing:CalipicUITests/$(basename "$file" .swift)/$name")
      done
      shift 2 ;;
    --workers) workers="$2"; shift 2 ;;
    --result) rm -rf "build/$2.xcresult"; result=(-resultBundlePath "build/$2.xcresult"); shift 2 ;;
    --language)
      region="${2#*-}"; [[ "$region" == "$2" ]] && region="$(echo "$2" | tr '[:lower:]' '[:upper:]')"
      language=(-testLanguage "$2" -testRegion "$region"); shift 2 ;;
    --no-build) action=test-without-building; shift ;;
    *) break ;;
  esac
done
if [[ $# -ne 1 ]]; then
  echo 'Usage: scripts/test.sh [--unit | --ui name,name] [--workers N] [--result NAME] [--language CODE] [--no-build] auto|"platform=iOS Simulator,id=<simulator UUID>"' >&2
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
iphones = [device for runtime in sorted(devices, reverse=True)
           if ".iOS-" in runtime and int(runtime.split(".iOS-")[1].split("-")[0]) >= 27
           for device in devices[runtime] if "iPhone" in device["name"]]
# A simulator that is already running first: it is the one the screenshots were checked on, and it saves a boot.
iphones.sort(key=lambda device: device["state"] != "Booted")
if iphones: print(iphones[0]["udid"])
')
  if [[ -z "$id" ]]; then echo "No iPhone simulator with iOS 27 or later is available." >&2; exit 1; fi
  destination="platform=iOS Simulator,id=$id"
fi

# xcodebuild spreads whole test classes over the clones, so the UI tests are split into four classes of about the
# same length (Calipic/UITests). A handful of named tests runs on one simulator.
parallel=(-parallel-testing-enabled NO)
if [[ "$workers" -gt 1 && ${#only[@]} -eq 0 ]]; then
  parallel=(-parallel-testing-enabled YES -parallel-testing-worker-count "$workers")
fi
echo "Testing on: $destination (${parallel[*]})"

exec xcodebuild \
  -project Calipic/Calipic.xcodeproj \
  -scheme Calipic \
  -destination "$destination" \
  -derivedDataPath build/DerivedData \
  ${only[@]+"${only[@]}"} \
  ${result[@]+"${result[@]}"} \
  ${language[@]+"${language[@]}"} \
  "${parallel[@]}" \
  CODE_SIGNING_ALLOWED=NO "$action"
