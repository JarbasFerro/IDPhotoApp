#!/usr/bin/env python3
"""Regenerates the provisional brand test assets in the spike's asset catalog.

- BrandAccentA…D colorsets: the shared *provisional* test palette (any/dark x normal/high contrast, sRGB). This is
  the accent role: text, glyphs, selection.
- BrandAccentFillA…D colorsets: the accent FILL role, for filled buttons under a white label. Each fill is derived
  from the accent of the same appearance (same hue and saturation, lightness lowered only as far as needed) and the
  script fails if any fill gives a white label less than 4.5:1.
- AppIcon: a placeholder rendered from the v2 finished teal study (docs/brand/prototypes/icon-v2, built by
  scripts/brand/build-icon-v2.py), which is already a full-bleed opaque square as iOS requires. The symbol form is
  still a candidate (BD-036), so this stays a Debug-only placeholder.

None of these values are brand decisions. Requires inkscape and sips on PATH.
"""
import colorsys
import json
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOG = ROOT / "Spikes/IDPhotoSpike/App/Resources/Assets.xcassets"
ICON_SVG = ROOT / "docs/brand/prototypes/icon-v2/v2-finished-teal.svg"
INFO = {"author": "xcode", "version": 1}

# id: (light, dark, increase-contrast light, increase-contrast dark)
PALETTE = {
    "A": ("1F3FA8", "7C98F5", "142C7A", "A9BCFF"),
    "B": ("0E6F7C", "4FC3D1", "084C55", "8ADFE9"),
    # C and D light are the round-1 corrections (03-accessibility-color.md): 4.5:1 as text on white.
    "C": ("51728E", "9DB7CF", "3D5A73", "C3D6E6"),
    "D": ("A45E00", "F0B55A", "7A4800", "FFD08A"),
}

ON_FILL = "FFFFFF"
# Minimum contrast of the white label on a fill: WCAG AA for text; AAA under Increase Contrast.
FILL_CONTRAST = 4.5
FILL_CONTRAST_INCREASED = 7.0
# In the order of a PALETTE row.
FILL_MINIMUMS = (FILL_CONTRAST, FILL_CONTRAST, FILL_CONTRAST_INCREASED, FILL_CONTRAST_INCREASED)



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


def relative_luminance(hex_value):
    def linear(channel):
        channel /= 255
        return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
    red, green, blue = (linear(int(hex_value[i:i + 2], 16)) for i in (0, 2, 4))
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def contrast(first, second):
    """WCAG 2 contrast ratio of two sRGB hex colours."""
    lighter, darker = sorted((relative_luminance(first), relative_luminance(second)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def derive_fill(accent, minimum):
    """The accent itself when a white label already reaches `minimum` on it; otherwise the same HLS hue and
    saturation with the lightness lowered, in 0.1 % steps, to the first value that does."""
    hue, lightness, saturation = colorsys.rgb_to_hls(*(int(accent[i:i + 2], 16) / 255 for i in (0, 2, 4)))
    fill, step = accent, round(lightness * 1000)
    while contrast(fill, ON_FILL) < minimum:
        step -= 1
        if step < 0:
            raise SystemExit(f"No fill derived from #{accent} gives a #{ON_FILL} label {minimum}:1.")
        fill = "%02X%02X%02X" % tuple(round(c * 255) for c in colorsys.hls_to_rgb(hue, step / 1000, saturation))
    return fill


def fills(palette=None):
    """id: (light, dark, increase-contrast light, increase-contrast dark), in the order of PALETTE."""
    return {identifier: tuple(derive_fill(accent, minimum) for accent, minimum in zip(accents, FILL_MINIMUMS))
            for identifier, accents in (palette or PALETTE).items()}


def check_fills(fill_palette):
    """Exits with an error if a white label on any fill is below its minimum (4.5:1; 7:1 under Increase Contrast),
    whatever produced the values."""
    failures = [f"BrandAccentFill{identifier} #{fill}: {contrast(fill, ON_FILL):.2f}:1, needs {minimum}:1"
                for identifier, values in fill_palette.items() for fill, minimum in zip(values, FILL_MINIMUMS)
                if contrast(fill, ON_FILL) < minimum]
    if failures:
        raise SystemExit(f"Fill too light for a #{ON_FILL} label: " + "; ".join(failures))


def write_colorset(name, values):
    light, dark, ic_light, ic_dark = values
    write_json(CATALOG / f"{name}.colorset/Contents.json", {
        "colors": [
            color_entry(light, False, False),
            color_entry(dark, True, False),
            color_entry(ic_light, False, True),
            color_entry(ic_dark, True, True),
        ],
        "info": INFO,
    })


def main():
    fill_palette = fills()
    check_fills(fill_palette)
    write_json(CATALOG / "Contents.json", {"info": INFO})
    for identifier, values in PALETTE.items():
        write_colorset(f"BrandAccent{identifier}", values)
        write_colorset(f"BrandAccentFill{identifier}", fill_palette[identifier])
        print(f"{identifier} fill  " + "  ".join(f"#{fill} {contrast(fill, ON_FILL):.2f}:1" for fill in fill_palette[identifier]))

    icon_name = "AppIcon-v2-teal-placeholder.png"
    write_json(CATALOG / "AppIcon.appiconset/Contents.json", {
        "images": [{"filename": icon_name, "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": INFO,
    })
    for stale in (CATALOG / "AppIcon.appiconset").glob("*.png"):
        stale.unlink()
    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)
        (scratch / "icon.svg").write_text(ICON_SVG.read_text())
        subprocess.run(["inkscape", str(scratch / "icon.svg"), "-w", "1024", "-h", "1024",
                        "--export-background=#FFFFFF", "--export-background-opacity=1",
                        "-o", str(scratch / "icon.png")], check=True)
        # App icons must not carry an alpha channel; a JPEG round trip through sips drops it, which is good
        # enough for a placeholder.
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100",
                        str(scratch / "icon.png"), "--out", str(scratch / "icon.jpg")], check=True, capture_output=True)
        subprocess.run(["sips", "-s", "format", "png", str(scratch / "icon.jpg"),
                        "--out", str(CATALOG / "AppIcon.appiconset" / icon_name)], check=True, capture_output=True)


if __name__ == "__main__":
    main()
