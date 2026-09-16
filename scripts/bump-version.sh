#!/bin/bash
# Sets the spike app's marketing version and derives the build number from the git commit count,
# so every build shown in the app can be traced to a commit. Run before committing app changes:
#   scripts/bump-version.sh 0.3.0
# Then commit, and tag the commit with v<version> when it is a version you hand to a device.
set -euo pipefail
if [[ $# -ne 1 ]]; then echo "usage: scripts/bump-version.sh <marketing version, e.g. 0.3.0>" >&2; exit 2; fi
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project="$repo_root/Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj/project.pbxproj"
marketing="$1"
# +1 because the commit that carries this change is not counted yet.
build=$(( $(git -C "$repo_root" rev-list --count HEAD) + 1 ))
sed -i '' -E "s/MARKETING_VERSION = \"?[^;\"]*\"?;/MARKETING_VERSION = $marketing;/g; s/CURRENT_PROJECT_VERSION = \"?[^;\"]*\"?;/CURRENT_PROJECT_VERSION = $build;/g" "$project"
echo "IDPhotoSpike version $marketing build $build"
grep -oE 'MARKETING_VERSION = [^;]*;|CURRENT_PROJECT_VERSION = [^;]*;' "$project" | sort -u
