#!/usr/bin/env bash
# Export UI test screenshots from an .xcresult bundle into a fixed-name gallery.
#
# Usage: scripts/ui/export-gallery.sh <path/to/result.xcresult> [output-dir]
# Default output-dir: docs/ui/gallery (relative to the repository root).
# Existing files in the output directory are never deleted.
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

usage() {
    echo "usage: $(basename "$0") <path/to/result.xcresult> [output-dir]" >&2
}

if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    usage
    exit 2
fi

if [ ! -e "$1" ]; then
    echo "error: result bundle not found: $1" >&2
    usage
    exit 2
fi

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
xcresult_path="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
xcresult_name="$(basename "$xcresult_path")"
out_dir="${2:-$repo_root/docs/ui/gallery}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

xcrun xcresulttool export attachments --path "$xcresult_path" --output-path "$tmp_dir"

python3 - "$tmp_dir" "$out_dir" "$xcresult_name" <<'EOF'
import datetime
import json
import os
import re
import subprocess
import sys

tmp_dir, out_dir, xcresult_name = sys.argv[1], sys.argv[2], sys.argv[3]
skip_prefixes = ("App Screenshot", "Element Screenshot", "UI Snapshot", "brand-")

with open(os.path.join(tmp_dir, "manifest.json"), encoding="utf-8") as fh:
    manifest = json.load(fh)

seen = set()
exported = []  # (file name, screen name)

for test in manifest:
    for attachment in test.get("attachments", []):
        suggested = attachment.get("suggestedHumanReadableName", "") or ""
        exported_name = attachment.get("exportedFileName")
        if not suggested.endswith(".png") or "_0_" not in suggested:
            continue
        if suggested.startswith(skip_prefixes):
            continue
        if not exported_name:
            continue

        screen = suggested.split("_0_", 1)[0]
        slug = screen.lower().replace(", ", "-").replace(" ", "-")
        slug = re.sub(r"[^a-z0-9-]", "", slug)
        if not slug:
            continue
        file_name = slug + ".png"
        if file_name in seen:
            continue  # keep the first attachment for a name
        seen.add(file_name)

        src = os.path.join(tmp_dir, exported_name)
        dst = os.path.join(out_dir, file_name)
        if not os.path.isfile(src):
            raise SystemExit(f"error: exported file missing: {exported_name}")
        subprocess.run(
            ["sips", "-Z", "1100", src, "--out", dst],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        exported.append((file_name, screen))

exported.sort(key=lambda item: item[0])

today = datetime.date.today().isoformat()
lines = [
    "# Screenshot gallery",
    "",
    f"Exported from {xcresult_name} on {today} by scripts/ui/export-gallery.sh. "
    "Light and Dark where the tests capture both.",
    "",
]
lines += [f"- [{screen}]({file_name})" for file_name, screen in exported]
with open(os.path.join(out_dir, "README.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")

print(f"Exported {len(exported)} screenshots to {out_dir}")
EOF
