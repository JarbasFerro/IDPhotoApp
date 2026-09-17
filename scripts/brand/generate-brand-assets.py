#!/usr/bin/env python3
"""Regenerates the provisional brand test assets in the spike's asset catalog.

- BrandAccentA…D colorsets: the shared *provisional* test palette (any/dark x normal/high contrast, sRGB).
- AppIcon: a labelled placeholder rendered from docs/brand/assets/calipic-icon-draft-v0.svg. The draft geometry is
  used untouched; only the rounded preview tile is swapped for a full-bleed opaque white square, as iOS requires
  (the system applies its own mask). Neutral white field, mark #111111: a draft placeholder, not a colour pick.

None of these values are brand decisions. Requires inkscape and sips on PATH.
"""
import json
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOG = ROOT / "Spikes/IDPhotoSpike/App/Resources/Assets.xcassets"
DRAFT_SVG = ROOT / "docs/brand/assets/calipic-icon-draft-v0.svg"
INFO = {"author": "xcode", "version": 1}

# id: (light, dark, increase-contrast light, increase-contrast dark)
PALETTE = {
    "A": ("1F3FA8", "7C98F5", "142C7A", "A9BCFF"),
    "B": ("0E6F7C", "4FC3D1", "084C55", "8ADFE9"),
    "C": ("5B7C99", "9DB7CF", "3D5A73", "C3D6E6"),
    "D": ("B26A00", "F0B55A", "7A4800", "FFD08A"),
}

PREVIEW_TILE = '<rect x="28" y="28" width="968" height="968" rx="216" fill="#FFFFFF" stroke="#D9D9D9" stroke-width="4"/>'
FULL_BLEED = '<rect x="0" y="0" width="1024" height="1024" fill="#FFFFFF"/>'


def write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def color_entry(hex_value, dark, high_contrast):
    entry = {}
    appearances = []
    if dark:
        appearances.append({"appearance": "luminosity", "value": "dark"})
    if high_contrast:
        appearances.append({"appearance": "contrast", "value": "high"})
    if appearances:
        entry["appearances"] = appearances
    entry["color"] = {
        "color-space": "srgb",
        "components": {
            "alpha": "1.000",
            "red": "0x" + hex_value[0:2],
            "green": "0x" + hex_value[2:4],
            "blue": "0x" + hex_value[4:6],
        },
    }
    entry["idiom"] = "universal"
    return entry


def main():
    write_json(CATALOG / "Contents.json", {"info": INFO})
    for identifier, (light, dark, ic_light, ic_dark) in PALETTE.items():
        write_json(CATALOG / f"BrandAccent{identifier}.colorset/Contents.json", {
            "colors": [
                color_entry(light, False, False),
                color_entry(dark, True, False),
                color_entry(ic_light, False, True),
                color_entry(ic_dark, True, True),
            ],
            "info": INFO,
        })

    icon_name = "AppIcon-draft-v0-placeholder.png"
    write_json(CATALOG / "AppIcon.appiconset/Contents.json", {
        "images": [{"filename": icon_name, "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": INFO,
    })
    svg = DRAFT_SVG.read_text()
    if PREVIEW_TILE not in svg:
        raise SystemExit("The draft SVG's preview tile changed; update PREVIEW_TILE before regenerating the placeholder.")
    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)
        (scratch / "icon.svg").write_text(svg.replace(PREVIEW_TILE, FULL_BLEED))
        subprocess.run(["inkscape", str(scratch / "icon.svg"), "-w", "1024", "-h", "1024",
                        "--export-background=#FFFFFF", "--export-background-opacity=1",
                        "-o", str(scratch / "icon.png")], check=True)
        # App icons must not carry an alpha channel; a JPEG round trip through sips drops it losslessly enough
        # for a two-tone placeholder.
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100",
                        str(scratch / "icon.png"), "--out", str(scratch / "icon.jpg")], check=True, capture_output=True)
        subprocess.run(["sips", "-s", "format", "png", str(scratch / "icon.jpg"),
                        "--out", str(CATALOG / "AppIcon.appiconset" / icon_name)], check=True, capture_output=True)


if __name__ == "__main__":
    main()
