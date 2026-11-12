#!/usr/bin/env python3
"""Fail when the app's words break the plain-language rule (docs/03-design.md §4).

Scans the English text of every live entry in the String Catalog for technical words people should not need.
An entry may stay only if it is listed in ALLOWED with a reason. The list may shrink, never grow quietly:
an allowed entry that no longer exists also fails, so the list stays honest.

Usage: python3 scripts/strings/check_copy.py [path/to/Localizable.xcstrings]
"""
import json
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
CATALOG = os.path.join(ROOT, "Calipic", "App", "Resources", "Localizable.xcstrings")

BANNED = re.compile(r"\b(JPEG|JPG|PDF|pixels?|px|DPI|ppi|segmentation|mask|ICAO|bleed)\b", re.IGNORECASE)

ALLOWED = {
    # Error recovery: naming the formats is the fix.
    "This photo could not be opened. Choose a JPEG, HEIC, or PNG image.": "error recovery",
    # A digital-only document has no physical size; its pixel size is the fact people look for.
    "%lld × %lld px": "size of a digital-only document",
}


def english(key, entry):
    unit = entry.get("localizations", {}).get("en", {}).get("stringUnit", {})
    return unit.get("value", key)


def check(path):
    strings = json.load(open(path, encoding="utf-8"))["strings"]
    errors = []
    for key, entry in strings.items():
        if entry.get("extractionState") == "stale":
            continue
        text = english(key, entry)
        found = BANNED.search(text)
        if found and key not in ALLOWED:
            errors.append(f"technical word '{found.group(0)}' in: {text!r}")
    for key in ALLOWED:
        if key not in strings or strings[key].get("extractionState") == "stale":
            errors.append(f"allowed entry no longer exists; remove it from ALLOWED: {key!r}")
    return errors


def main():
    errors = check(sys.argv[1] if len(sys.argv) > 1 else CATALOG)
    if errors:
        print("\n".join(errors))
        print(f"FAILED: {len(errors)} wording problem(s)")
        sys.exit(1)
    print("OK: wording follows the plain-language rule")


if __name__ == "__main__":
    main()
