# The Calipic app (`IDPhotoSpike`)

This folder is the app. It started as a feasibility spike and kept the name; it is the product now, and renaming it is on the [roadmap](../../docs/02-roadmap.md) (E1). What it does is described in [docs/01-product.md](../../docs/01-product.md); how the code is organised is in [docs/04-architecture.md](../../docs/04-architecture.md).

## Run

1. Open `IDPhotoSpike.xcodeproj` in Xcode 27 and select the shared `IDPhotoSpike` scheme.
2. Choose an iPhone simulator or a connected iPhone (iOS 27 is the minimum from version 0.17), and run.
3. On a simulator there is no camera: use **Choose from Library**.

For an iPhone: select a development team under Signing & Capabilities, pair the phone, and enable Developer Mode. No signing identity is in the repository.

From the repository root:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices available
scripts/test-spike.sh 'platform=iOS Simulator,id=<simulator UUID>'
```

Build, install, and screenshot commands are in the [handoff](../../docs/00-handoff.md).

## Versions

Home shows `marketing version (build)`. The marketing version is `0.<milestone>.<fix>` until release; the build number is the git commit count, set by `scripts/bump-version.sh <version>` before committing app changes. Commits handed to a device are tagged `v<version>`.

## Data lifetime

- A picked or captured photo is copied into a private, protected folder. The original in the photo library is never changed.
- Working files are removed when a photo is replaced or removed, and everything is wiped at the next launch.
- Export files exist only while the screen that offers them is open.
- Files the person saves or shares belong to where they were sent; the app does not delete them.

## Test fixtures and private portraits

- Tests generate coloured geometry images at run time, including rotations, metadata, HEIC and PNG, wide colour, and a 48-megapixel case. No real face is committed.
- Debug builds accept `--uitesting-fixture`, `--uitesting-fixture-2`, `--uitesting-custom-size`, and `--uitesting-fresh` (see [architecture §9](../../docs/04-architecture.md)).
- For real faces, put consented portraits in `<repo>/pics/` (git-ignored) and run `scripts/face-harness.sh`. It writes a report, annotated previews, masks, and aligned crops to `Artifacts/face-report/` (git-ignored).

## App icons

The app icon and its 32 alternates are generated: edit `VARIANTS` in `scripts/brand/build-icon-v2.py`, then run `scripts/brand/generate-brand-assets.py`. The masters are in `docs/brand/assets/`.

## Limits that are guesses, not measurements

Inputs are limited to 80 megapixels, 150 MB, and 16,384 pixels on a side. These are provisional and have not been measured on devices ([roadmap track P](../../docs/02-roadmap.md)).
