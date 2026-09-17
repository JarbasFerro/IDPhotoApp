#!/usr/bin/env python3
"""Regenerates the provisional brand test assets in the spike's asset catalog.

- BrandAccentA…D colorsets: the shared *provisional* test palette (any/dark x normal/high contrast, sRGB). This is
  the accent role: text, glyphs, selection.
- BrandAccentFillA…D colorsets: the accent FILL role, for filled buttons under a white label. Each fill is derived
  from the accent of the same appearance (same hue and saturation, lightness lowered only as far as needed) and the
  script fails if any fill gives a white label less than 4.5:1.
- The choose-your-icon set (BD-038), all derived from VARIANTS in scripts/brand/build-icon-v2.py:
  - AppIcon + AppIcon-<name>: one app-icon set per VARIANTS entry. The first entry is the primary `AppIcon`, every
    other one is an alternate `AppIcon-<name>`. Each is a single 1024 universal iOS image, full-bleed, without
    alpha. They are rendered WITHOUT the paper-grain layer and without dithering, all of them alike: with grain the
    PNGs weigh about 890 KB each, without about 100 KB (ICON_GRAIN below).
  - IconPreview-<name>: a small image per character for the in-app picker, pre-masked with the iOS icon corner
    shape.
  - App/Brand/AppIconCatalog.swift: the character list the app reads.
  - project.pbxproj: the value of ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES (Debug and Release). Alternates
    only reach the built app when the build settings list them.
  The symbol form is still a candidate (BD-036), so the drawings remain working drawings.

Changing the set is: edit VARIANTS, run this script, add or remove the "AppIcon.<name>" labels (en, es, pt-BR) in
App/Resources/Localizable.xcstrings. `--check` (also run at the end of a normal run) writes nothing and fails when
the build settings, the asset catalog, the Swift list or the label strings disagree with VARIANTS.

None of these values are brand decisions. Requires inkscape on PATH.
"""
import colorsys
import importlib.util
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPIKE = ROOT / "Spikes/IDPhotoSpike"
CATALOG = SPIKE / "App/Resources/Assets.xcassets"
STRINGS = SPIKE / "App/Resources/Localizable.xcstrings"
PROJECT = SPIKE / "IDPhotoSpike.xcodeproj/project.pbxproj"
ICON_CATALOG_SWIFT = SPIKE / "App/Brand/AppIconCatalog.swift"
INFO = {"author": "xcode", "version": 1}

# The icon geometry lives in build-icon-v2.py; its file name has hyphens, so it is loaded by path.
_spec = importlib.util.spec_from_file_location("build_icon_v2", pathlib.Path(__file__).with_name("build-icon-v2.py"))
icon_builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(icon_builder)

PRIMARY_ICON = "AppIcon"
# Grain is the main PNG-size cost. One switch for ALL icons, so the set stays consistent.
ICON_GRAIN = False
ICON_PIXELS = 1024
PREVIEW_PIXELS = 240
# Corner radius of the iOS icon shape as a share of the side; the same value build-icon-v2.py uses in its sheets.
ICON_CORNER_RATIO = 0.2237
# Picker sections, in display order; AppIconChoice.Group in the app has the same cases.
GROUPS = ["people", "fun"]
LANGUAGES = ["en", "es", "pt-BR"]

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


def characters():
    """Character names in VARIANTS order; the first one is the default icon."""
    return list(icon_builder.VARIANTS)


def group_of(character):
    return icon_builder.VARIANTS[character][0]


def app_icon_name(character):
    return PRIMARY_ICON if character == characters()[0] else f"{PRIMARY_ICON}-{character}"


def preview_name(character):
    return f"IconPreview-{character}"


def label_key(character):
    """String Catalog key of the character's accessibility label."""
    return f"AppIcon.{character}"


def alternate_icon_setting():
    """The value of ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES."""
    return " ".join(app_icon_name(character) for character in characters()[1:])


def build_settings():
    return {"ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": alternate_icon_setting(),
            "ASSETCATALOG_COMPILER_APPICON_NAME": PRIMARY_ICON,
            "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES"}


def wanted_asset_directories():
    return ({f"{app_icon_name(c)}.appiconset" for c in characters()}
            | {f"{preview_name(c)}.imageset" for c in characters()})


def icon_asset_directories(catalog):
    return list(catalog.glob("AppIcon*.appiconset")) + list(catalog.glob("IconPreview-*.imageset"))


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise SystemExit(f"finished_svg() in build-icon-v2.py changed: expected exactly one {old!r}")
    return text.replace(old, new)


def icon_svg(character, grain=None, corner_mask=False):
    """The finished teal icon from build-icon-v2.py, adapted as text so that file stays untouched:
    `grain=False` drops the paper-grain layer; `corner_mask=True` clips to the iOS icon corner shape for in-app
    previews (app icons themselves must stay full-bleed; the system masks them)."""
    grain = ICON_GRAIN if grain is None else grain
    full = icon_builder.FULL
    spec = icon_builder.Spec(full.stroke, full.net_gap, full.right_sweep, shift_x=full.shift_x, bust=character)
    svg = icon_builder.finished_svg(spec, character, icon_builder.FINISHES["teal"])
    if not grain:
        svg = replace_once(svg, '  <rect width="1024" height="1024" filter="url(#grain)" opacity="0.10"/>\n', "")
    if corner_mask:
        radius = ICON_CORNER_RATIO * 1024
        svg = replace_once(svg, "  </defs>\n",
                           f'    <clipPath id="corner"><rect width="1024" height="1024" rx="{radius:.2f}"/></clipPath>\n'
                           '  </defs>\n  <g clip-path="url(#corner)">\n')
        svg = replace_once(svg, "</svg>\n", "  </g>\n</svg>\n")
    return svg


def render(svg_text, png, pixels, alpha, scratch):
    svg = scratch / (png.stem + ".svg")
    svg.write_text(svg_text)
    # RGB_8 writes a PNG without an alpha channel, as app icons require. No dithering: the noise it adds to the
    # gradients quadruples the file size and is not visible.
    result = subprocess.run(["inkscape", str(svg), "-w", str(pixels), "-h", str(pixels),
                             f"--export-png-color-mode={'RGBA_8' if alpha else 'RGB_8'}",
                             "--export-png-compression=9", "--export-png-use-dithering=false", "-o", str(png)],
                            capture_output=True, text=True)
    if result.returncode != 0 or not png.exists():
        raise SystemExit(f"inkscape could not render {png.name} (inkscape 1.3 or later is needed):\n{result.stderr}")


def icon_assets():
    """(character, is preview, asset name, directory name, pixels) for every asset of the set."""
    for character in characters():
        yield character, False, app_icon_name(character), f"{app_icon_name(character)}.appiconset", ICON_PIXELS
        yield character, True, preview_name(character), f"{preview_name(character)}.imageset", PREVIEW_PIXELS


def asset_contents(name, preview):
    image = {"filename": f"{name}.png", "idiom": "universal"}
    if not preview:
        image.update({"platform": "ios", "size": f"{ICON_PIXELS}x{ICON_PIXELS}"})
    return {"images": [image], "info": INFO}


def write_icons():
    if not shutil.which("inkscape"):
        raise SystemExit("inkscape is required")
    total = {False: 0, True: 0}
    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)
        # Render everything first: the catalog is only touched once every image exists.
        for character, preview, name, _, pixels in icon_assets():
            render(icon_svg(character, corner_mask=preview), scratch / f"{name}.png", pixels, alpha=preview,
                   scratch=scratch)
        for stale in icon_asset_directories(CATALOG):
            shutil.rmtree(stale)
        for _, preview, name, directory, _ in icon_assets():
            write_json(CATALOG / directory / "Contents.json", asset_contents(name, preview))
            shutil.move(str(scratch / f"{name}.png"), str(CATALOG / directory / f"{name}.png"))
            total[preview] += (CATALOG / directory / f"{name}.png").stat().st_size
    print(f"{len(characters())} app icons: {total[False] / 1e6:.2f} MB; previews: {total[True] / 1e6:.2f} MB "
          f"(grain {'on' if ICON_GRAIN else 'off'})")


def swift_catalog():
    """App/Brand/AppIconCatalog.swift: the character list the app reads, in VARIANTS order."""
    rows = "\n".join(f'        AppIconChoice(name: "{c}", group: .{group_of(c)}),' for c in characters())
    return f"""// Generated by scripts/brand/generate-brand-assets.py from VARIANTS in scripts/brand/build-icon-v2.py.
// Do not edit: change VARIANTS and regenerate. The first entry is the primary app icon.

extension AppIconChoice {{
    static let all: [AppIconChoice] = [
{rows}
    ]
}}
"""


def updated_project(project_text):
    """project.pbxproj with the three app-icon build settings of the app target set from VARIANTS. The settings
    must already exist (Debug and Release); only their values are rewritten."""
    for key, value in build_settings().items():
        quoted = value if re.fullmatch(r"[A-Za-z0-9_./]+", value) else f'"{value}"'
        project_text, count = re.subn(rf"^(\s*){key} = [^;]*;$",
                                      lambda match, key=key, quoted=quoted: f"{match.group(1)}{key} = {quoted};",
                                      project_text, flags=re.MULTILINE)
        if count != 2:
            raise SystemExit(f"project.pbxproj: expected {key} in Debug and Release of the app target, found {count}")
    return project_text


def png_header(path):
    """(width, height, PNG colour type): colour type 2 is RGB without alpha, 6 is RGBA."""
    data = path.read_bytes()[:26]
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    return int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big"), data[25]


def icon_sync_problems(project_text=None, swift_text=None, strings=None, catalog=None):
    """Everything that disagrees with VARIANTS: build settings, asset catalog, the generated Swift list and the
    label strings. Empty when in sync."""
    project_text = PROJECT.read_text() if project_text is None else project_text
    if swift_text is None and ICON_CATALOG_SWIFT.exists():
        swift_text = ICON_CATALOG_SWIFT.read_text()
    strings = json.loads(STRINGS.read_text())["strings"] if strings is None else strings
    catalog = catalog or CATALOG
    problems = []

    if updated_project(project_text) != project_text:
        problems.append("project.pbxproj: the app-icon build settings differ from VARIANTS; expected "
                        + "; ".join(f"{key} = {value}" for key, value in build_settings().items()))
    if swift_text != swift_catalog():
        problems.append(f"{ICON_CATALOG_SWIFT.name} is not what VARIANTS generates")

    for character, preview, name, directory, pixels in icon_assets():
        png, contents = catalog / directory / f"{name}.png", catalog / directory / "Contents.json"
        if not png.exists():
            problems.append(f"missing {directory}/{name}.png")
        elif png_header(png) != (pixels, pixels, 6 if preview else 2):
            problems.append(f"{directory}/{name}.png must be {pixels} px, {'RGBA' if preview else 'RGB without alpha'}")
        if not contents.exists() or json.loads(contents.read_text()) != asset_contents(name, preview):
            problems.append(f"{directory}/Contents.json is not what the generator writes")
    for character in characters():
        localizations = strings.get(label_key(character), {}).get("localizations", {})
        for language in LANGUAGES:
            if not localizations.get(language, {}).get("stringUnit", {}).get("value"):
                problems.append(f'Localizable.xcstrings: "{label_key(character)}" has no {language} label')
    on_disk = {path.name for path in icon_asset_directories(catalog)}
    problems += [f"stale {name} in the asset catalog" for name in sorted(on_disk - wanted_asset_directories())]
    labels = {key for key in strings if key.startswith(label_key(""))}
    problems += [f'Localizable.xcstrings: "{key}" has no character in VARIANTS'
                 for key in sorted(labels - {label_key(c) for c in characters()})]

    groups = [group_of(c) for c in characters()]
    if not set(groups) <= set(GROUPS) or groups != sorted(groups, key=GROUPS.index):
        problems.append(f"VARIANTS must list the groups in the order {GROUPS} and use no other group")
    return problems


def check_icon_sync():
    print(f'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "{alternate_icon_setting()}";')
    problems = icon_sync_problems()
    if problems:
        raise SystemExit("Choose-your-icon set out of sync:\n  " + "\n  ".join(problems))


def main():
    if "--check" in sys.argv[1:]:
        check_icon_sync()
        return
    fill_palette = fills()
    check_fills(fill_palette)
    write_json(CATALOG / "Contents.json", {"info": INFO})
    for identifier, values in PALETTE.items():
        write_colorset(f"BrandAccent{identifier}", values)
        write_colorset(f"BrandAccentFill{identifier}", fill_palette[identifier])
        print(f"{identifier} fill  " + "  ".join(f"#{fill} {contrast(fill, ON_FILL):.2f}:1" for fill in fill_palette[identifier]))

    write_icons()
    ICON_CATALOG_SWIFT.write_text(swift_catalog())
    PROJECT.write_text(updated_project(PROJECT.read_text()))
    check_icon_sync()


if __name__ == "__main__":
    main()
