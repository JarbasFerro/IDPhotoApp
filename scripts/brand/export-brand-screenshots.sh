#!/bin/bash
# Runs the brand product-context capture UI tests once per appearance and exports their screenshots into
# Artifacts/brand-review/ with human-readable names (brand-<candidate>-<appearance>-<Screen>.png) plus a manifest.json.
# Artifacts/ is gitignored: the export is regenerable evidence. The screenshots that
# docs/brand/prototypes/04-product-context.md embeds are downscaled copies in docs/brand/prototypes/product-context/.
#
# Passes: light, dark. Set BRAND_REVIEW_INCREASE_CONTRAST=1 to add lightIC and darkIC (Increase Contrast) passes.
# If a pass fails, whatever was captured stays in build/brand-review-staging and the previous export is kept.
set -euo pipefail

if [[ $# -ne 1 || "$1" != *"id="* ]]; then
  echo 'Usage: scripts/brand/export-brand-screenshots.sh "platform=iOS Simulator,id=<simulator UUID>"' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

destination="$1"
udid="${destination##*id=}"
udid="${udid%%,*}"
output_dir="Artifacts/brand-review"
staging_dir="build/brand-review-staging"
doc="docs/brand/prototypes/04-product-context.md"
doc_dir="docs/brand/prototypes/product-context"
passes=(light dark)
if [[ "${BRAND_REVIEW_INCREASE_CONTRAST:-0}" == "1" ]]; then
  passes+=(lightIC darkIC)
fi

# simctl can only change the appearance of a booted simulator. XCUIDevice.shared.appearance had no effect on the
# iOS 26 simulator, so the appearance is set here and passed to the tests for the attachment names.
xcrun simctl bootstatus "$udid" -b
previous_appearance="$(xcrun simctl ui "$udid" appearance)"
previous_contrast="$(xcrun simctl ui "$udid" increase_contrast)"
restore_simulator() {
  case "$previous_appearance" in light|dark) xcrun simctl ui "$udid" appearance "$previous_appearance" || true ;; esac
  case "$previous_contrast" in enabled|disabled) xcrun simctl ui "$udid" increase_contrast "$previous_contrast" || true ;; esac
}
trap restore_simulator EXIT

rm -rf "$staging_dir"
mkdir -p "$staging_dir"
action="test"
failed_passes=()
for pass in "${passes[@]}"; do
  case "$pass" in
    light*) xcrun simctl ui "$udid" appearance light ;;
    dark*) xcrun simctl ui "$udid" appearance dark ;;
  esac
  case "$pass" in
    *IC) xcrun simctl ui "$udid" increase_contrast enabled ;;
    *) xcrun simctl ui "$udid" increase_contrast disabled ;;
  esac

  result_bundle="build/brand-review-$pass.xcresult"
  raw_dir="build/brand-review-raw-$pass"
  rm -rf "$result_bundle" "$raw_dir"
  # TEST_RUNNER_-prefixed variables reach the test runner with the prefix stripped.
  if ! TEST_RUNNER_BRAND_CONTEXT_CAPTURE=1 TEST_RUNNER_BRAND_CONTEXT_APPEARANCE="$pass" xcodebuild \
    -project Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj \
    -scheme IDPhotoSpike \
    -destination "$destination" \
    -derivedDataPath build/DerivedData \
    -resultBundlePath "$result_bundle" \
    -only-testing:IDPhotoSpikeUITests/BrandContextUITests \
    CODE_SIGNING_ALLOWED=NO "$action"; then
    failed_passes+=("$pass")
    [[ -d "$result_bundle" ]] || continue
  fi
  action="test-without-building"

  xcrun xcresulttool export attachments --path "$result_bundle" --output-path "$raw_dir"
  python3 - "$raw_dir" "$staging_dir" <<'PY'
import json, pathlib, re, shutil, sys

raw, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
manifest_path = out / "manifest.json"
entries = json.loads(manifest_path.read_text()) if manifest_path.exists() else []
found = 0
for test in json.loads((raw / "manifest.json").read_text()):
    for attachment in test["attachments"]:
        # xcresulttool suggests "<attachment name>_<index>_<UUID>.png"; keep only our named screenshots.
        match = re.match(r"(brand-([A-Za-z]+)-([A-Za-z]+)-([A-Za-z]+))_\d+_[0-9A-Fa-f-]+\.png$",
                         attachment["suggestedHumanReadableName"])
        if not match:
            continue
        name, candidate, appearance, screen = match.groups()
        shutil.copyfile(raw / attachment["exportedFileName"], out / f"{name}.png")
        found += 1
        entries.append({
            "fileName": f"{name}.png",
            "candidate": candidate,
            "appearance": appearance,
            "screen": screen,
            "testIdentifier": test.get("testIdentifier"),
            "deviceName": attachment.get("deviceName"),
            "timestamp": attachment.get("timestamp"),
        })
entries.sort(key=lambda entry: entry["fileName"])
manifest_path.write_text(json.dumps(entries, indent=2) + "\n")
print(f"Staged {found} screenshots ({len(entries)} in total)")
PY
done

if [[ ${#failed_passes[@]} -gt 0 ]]; then
  echo "Capture failed for: ${failed_passes[*]}. Partial export left in $staging_dir; $output_dir was not replaced." >&2
  exit 1
fi

rm -rf "$output_dir"
mkdir -p "$(dirname "$output_dir")"
mv "$staging_dir" "$output_dir"
echo "Exported $(find "$output_dir" -name '*.png' | wc -l | tr -d ' ') screenshots to $output_dir"

# Committed, downscaled copies of exactly the screenshots the product-context document embeds.
doc_shots=()
while IFS= read -r shot; do doc_shots+=("$shot"); done \
  < <(grep -o 'product-context/brand-[A-Za-z-]*\.png' "$doc" | sed 's|product-context/||' | sort -u)
missing=()
for shot in "${doc_shots[@]}"; do
  if [[ ! -f "$output_dir/$shot" ]]; then
    # Increase Contrast shots are expected to be absent when those passes were not requested.
    if [[ "$shot" == *IC-* && "${BRAND_REVIEW_INCREASE_CONTRAST:-0}" != "1" ]]; then continue; fi
    missing+=("$shot")
  fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "$doc embeds screenshots this run did not produce: ${missing[*]}. $doc_dir was not touched." >&2
  exit 1
fi
mkdir -p "$doc_dir"
refreshed=0
for shot in "${doc_shots[@]}"; do
  [[ -f "$output_dir/$shot" ]] || continue
  sips -Z 1200 "$output_dir/$shot" --out "$doc_dir/$shot" >/dev/null
  refreshed=$((refreshed + 1))
done
echo "Refreshed $refreshed of ${#doc_shots[@]} document screenshots in $doc_dir"
