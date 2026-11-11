#!/usr/bin/env python3
"""Build the single catalog resource the app bundles, from Rules/catalog/v1.

The JSON files in Rules/ are the source of truth; the app reads one generated file so the bundle has no
name collisions. CI runs `--check` so the bundled copy can never drift from Rules/.

Usage:
  python3 scripts/rules/build_app_catalog.py          # write the app resource
  python3 scripts/rules/build_app_catalog.py --check  # exit 1 if the app resource is stale
"""
import json
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
CATALOG = os.path.join(ROOT, "Rules", "catalog", "v1")
TARGET = os.path.join(ROOT, "Spikes", "IDPhotoSpike", "App", "Resources", "CalipicCatalog.json")


def build():
    catalog = json.load(open(os.path.join(CATALOG, "catalog.json"), encoding="utf-8"))
    profiles = [json.load(open(os.path.join(CATALOG, "profiles", f"{pid}.json"), encoding="utf-8"))
                for pid in catalog["profiles"]]
    shortcuts = json.load(open(os.path.join(CATALOG, "custom-size-shortcuts.json"), encoding="utf-8"))
    bundle = {"schemaVersion": catalog["schemaVersion"], "catalogVersion": catalog["catalogVersion"],
              "profiles": profiles, "customSizes": shortcuts}
    return json.dumps(bundle, ensure_ascii=False, indent=1, sort_keys=True) + "\n"


def main():
    text = build()
    if "--check" in sys.argv:
        current = open(TARGET, encoding="utf-8").read() if os.path.exists(TARGET) else ""
        if current != text:
            print(f"STALE: run python3 scripts/rules/build_app_catalog.py to update {os.path.relpath(TARGET, ROOT)}")
            sys.exit(1)
        print("OK: app catalog is up to date")
        return
    with open(TARGET, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {os.path.relpath(TARGET, ROOT)}")


if __name__ == "__main__":
    main()
