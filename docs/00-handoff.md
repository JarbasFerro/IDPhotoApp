# 00 — Handoff: start here

For whoever continues this project, human or model. Read this page, then [AGENTS.md](../AGENTS.md) (the rules), then [02-roadmap.md](02-roadmap.md) (what to do next).

**State:** tag `v0.20.2` (the cutting-mat look; Adjust as an editor, compact Photo Check, new step marker, remove photos from Home), 2026-11-13. The founder's own portrait for local testing is at `test_data/local/founder-portrait.jpg` (ignored by git; never commit it or screenshots of it). The app is `Calipic/` (target, scheme, and module `Calipic`, bundle identifier `com.jarbasferro.calipic`). All tests pass on the iOS 27 simulator. CI has a Swift tests job, but GitHub's runner has no Xcode 27 yet, so it skips with a warning: run `scripts/test.sh auto` before every app commit. The app runs on the founder's iPhone.

## 1. What this is

Calipic is a native iPhone app for making ID photos at home and printing them yourself. The founder's goal is to be the #1 app in that category worldwide: easy, great quality, a correct print the first time, and a look and feel people enjoy.

## 2. The documents

| File | Read it for |
|---|---|
| [01-product.md](01-product.md) | What the product is, pricing, the journey, how "best" is measured |
| [02-roadmap.md](02-roadmap.md) | The plan to 1.0 and the next three batches of work |
| [03-design.md](03-design.md) | Part A: how the app looks and behaves today. Part B: the design direction and each proposal in detail |
| [04-architecture.md](04-architecture.md) | Code map, the life of a photo, concurrency, rules, credits, tests |
| [05-decisions.md](05-decisions.md) | Decisions in force, and the open ones waiting for the founder |
| [06-markets-and-documents.md](06-markets-and-documents.md) | Countries, documents, how to add a profile |
| [profiles/](profiles/README.md) | Sourced research behind every official profile |
| [ui/gallery/](ui/gallery/) | A screenshot of every screen at 0.16.0 |
| [ui/explorations/](ui/explorations/README.md) | Design rounds 1 and 2 with the options that were not chosen |

The repository used to hold about 75 documents. They were consolidated into these on 2026-11-12. Everything removed is in git history at tag `v0.16.0` (for example `git show v0.16.0:docs/10-decisions.md`).

## 3. Build, test, install

Always use the full Xcode: `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

```sh
# Simulators available on this Mac
xcrun simctl list devices available

# All tests (unit and UI) on the first iOS 27 iPhone simulator. Takes about five minutes.
scripts/test.sh auto
# Unit tests only, as CI will run them (seconds once built). A specific simulator also works:
scripts/test.sh --unit auto
scripts/test.sh "platform=iOS Simulator,id=<simulator UUID>"

# Result summary and screenshots from a run made with -resultBundlePath
xcrun xcresulttool get test-results summary --path build/<name>.xcresult
xcrun xcresulttool export attachments --path build/<name>.xcresult --output-path <folder>

# Checks that also run in CI
python3 scripts/rules/validate_catalog.py Rules/catalog/v1
python3 scripts/rules/build_app_catalog.py --check
python3 scripts/strings/check_copy.py

# Build for a connected iPhone, install, launch
xcrun devicectl list devices
xcodebuild -project Calipic/Calipic.xcodeproj -scheme Calipic -configuration Debug \
  -destination 'id=<device identifier>' -derivedDataPath build/DerivedDataDevice -allowProvisioningUpdates build
xcrun devicectl device install app --device <device identifier> build/DerivedDataDevice/Build/Products/Debug-iphoneos/Calipic.app
xcrun devicectl device process launch --device <device identifier> com.jarbasferro.calipic
```

Launching fails while the iPhone is locked; the install still succeeds.

## 4. How the founder works

- **Visuals and experience come first.** Look at screenshots of every changed screen in Light and Dark before committing. Fix clipping, wrapping, and weak contrast before reporting.
- **Nothing is final.** Suggest anything that would make the app look, feel, or perform better, and say plainly when you disagree with an earlier decision.
- **Commit and push to `main`** after each finished batch, without asking. Bump the version first: `scripts/bump-version.sh <version>`. Tag builds handed to the iPhone: `v<version>`. The version and build are visible at the bottom of Home.
- **Design choices go to the founder as options**, usually two or three mock-ups; the founder picks by number. Save every round as an image in `docs/ui/explorations/`.
- **Explain in plain language**, lead with what changed, and say what is not real yet.
- **Decisions the founder made are marked F** in [05-decisions.md](05-decisions.md). Do not reverse one silently.
- The repository is **public**. Never commit a real face, a device identifier, an account detail, or a secret.

## 5. Things that will save you time

- **New Swift files join the target automatically** (the project uses synchronised folders).
- **Strings:** every user-facing string needs Spanish and Portuguese (Brazil) in `App/Resources/Localizable.xcstrings`. `xcodebuild` does not update the catalog; add entries by editing the JSON (keep Xcode's formatting: two-space indent, `" : "` separators) and remove keys that are no longer used. A build writes `.stringsdata` files that list the keys the code uses; compare them with the catalog to find what is missing or dead.
- **A localisation key built by interpolation looks up the wrong key.** Build the key as a `String` first, then `String(localized: String.LocalizationValue(key))`.
- **Plain words are enforced:** `check_copy.py` fails on JPEG, PDF, pixel, DPI, and similar. Its allow-list may shrink, never grow quietly.
- **The simulator cannot run Vision.** `--uitesting-measured` (Debug only) gives the test photo a synthetic face so Photo Check's measuring can be screenshot.
- **UI tests** launch with `--uitesting-fresh` (Spain DNI, nothing saved, one credit, print panel suppressed). An accessibility identifier on a container hides its children's identifiers: put identifiers on leaf elements.
- **A disabled button accepts a tap silently in UI tests.** Wait for `isEnabled` first.
- **Appearance in UI tests:** `XCUIDevice.shared.appearance` has no effect on the iOS 27 simulator. For Dark screenshots set the simulator itself: `xcrun simctl ui <id> appearance dark`, run the test, then set it back to `light`.
- **The simulator has no camera and cannot run some Vision models.** Camera screens use a synthetic subject there; one private-portrait test is a known issue.
- **UI tests near the bottom edge:** a drag that starts in the bottom band is read as the go-home swipe and sends the app to the background, and every later tap lands on the Home Screen. Use `reveal(_:in:bottomClearance:)` before dragging a slider.
- **The bundle identifier changed in 0.19** (`com.jarbasferro.IDPhotoSpike` → `com.jarbasferro.calipic`). The old build is a separate app on a device, with its own credits and settings; delete it by hand.
- **Rules changes** need the validator, then `build_app_catalog.py`, then String Catalog entries for new names or checks.
- **Catalog and paper IDs are data:** paper chips are `paper-<id>` (`photo-4x6`, `a4`, …), profiles are `<country>.<document>.<variant>`.

## 6. What is not real yet

- **Purchases.** A pack adds credits without payment; the Credits screen says so.
- **Persistence.** Photos, edits, and unlocks are lost when the app closes. Credits already spent stay spent.
- **Evidence.** No print has been measured against tolerances, no speed or memory baseline exists, and no check is calibrated on real faces. Every machine check is advisory.
- **iOS 27 is the minimum** (deployment target 27.0 since 0.17). Run tests on the iOS 27 simulator "IDPhoto iPhone 15 Pro Max iOS 27" (id A1489838-4226-40EF-9FA3-F37A0CEEC1EE); the older iOS 26.5 simulator can no longer run the app.
- **Known gaps in 0.16.0:** changing the document relocks photos without a warning; the unlock card does not repeat open warnings from Photo Check; the true-size check has not yet been measured with a ruler on a real iPhone.

## 7. First things to do

1. Read [03-design.md](03-design.md) Part B and [02-roadmap.md §3](02-roadmap.md).
2. Read the founder's answers D-1 to D-8 at the end of [05-decisions.md](05-decisions.md); they shape the next batches.
3. Finish **0.20**: the look is built (cutting mat, design round 3 option B). Still open: U4, one continuous photo (zoom transitions, the portrait becomes its copies), and U10, real faces (needs the founder). Then 0.21, drafts.
