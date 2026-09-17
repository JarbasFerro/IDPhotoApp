#!/usr/bin/env python3
"""Unit tests for generate-brand-assets.py: the fill-role contrast logic and the choose-your-icon sync check
(stdlib only; renders nothing and writes only to a temporary copy of the asset catalog).

Run: python3 scripts/brand/test_generate_brand_assets.py
"""
import colorsys
import importlib.util
import json
import pathlib
import re
import shutil
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    "generate_brand_assets", pathlib.Path(__file__).with_name("generate-brand-assets.py"))
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def hue(hex_value):
    return colorsys.rgb_to_hls(*(int(hex_value[i:i + 2], 16) / 255 for i in (0, 2, 4)))[0]


class FillContrastTests(unittest.TestCase):
    def test_contrast_matches_wcag_reference_values(self):
        self.assertAlmostEqual(generator.contrast("000000", "FFFFFF"), 21.0, places=6)
        self.assertAlmostEqual(generator.contrast("FFFFFF", "FFFFFF"), 1.0, places=6)
        # #767676 is the well-known lightest grey that passes AA on white.
        self.assertAlmostEqual(generator.contrast("767676", "FFFFFF"), 4.54, places=2)
        self.assertEqual(generator.contrast("1F3FA8", "FFFFFF"), generator.contrast("FFFFFF", "1F3FA8"))

    def test_every_fill_meets_its_minimum_under_a_white_label(self):
        for identifier, (light, dark, ic_light, ic_dark) in generator.fills().items():
            for fill in (light, dark):
                self.assertGreaterEqual(generator.contrast(fill, "FFFFFF"), 4.5, f"{identifier} #{fill}")
            for fill in (ic_light, ic_dark):
                self.assertGreaterEqual(generator.contrast(fill, "FFFFFF"), 7.0, f"{identifier} #{fill}")

    def test_an_accent_that_already_passes_is_its_own_fill(self):
        self.assertEqual(generator.derive_fill("1F3FA8", 4.5), "1F3FA8")

    def test_a_derived_fill_is_deeper_and_keeps_the_hue(self):
        for identifier, accents in generator.PALETTE.items():
            accent, fill = accents[1], generator.fills()[identifier][1]
            self.assertLess(generator.relative_luminance(fill), generator.relative_luminance(accent), identifier)
            # 8-bit rounding moves the hue slightly; two degrees is far inside one hue family.
            self.assertAlmostEqual(hue(fill), hue(accent), delta=2 / 360, msg=identifier)

    def test_the_round_1_dark_accents_are_rejected_as_fills(self):
        with self.assertRaises(SystemExit) as failure:
            generator.check_fills({identifier: accents for identifier, accents in generator.PALETTE.items()})
        self.assertIn("BrandAccentFillA #7C98F5", str(failure.exception))

    def test_an_increase_contrast_fill_needs_seven_to_one(self):
        light, dark, ic_light, _ = generator.fills()["B"]
        with self.assertRaises(SystemExit):
            generator.check_fills({"B": (light, dark, ic_light, dark)})

    def test_an_unreachable_minimum_is_an_error_not_a_loop(self):
        with self.assertRaises(SystemExit):
            generator.derive_fill("7C98F5", 22)

    def test_passing_fills_are_accepted(self):
        generator.check_fills(generator.fills())


class AppIconSetTests(unittest.TestCase):
    def test_the_repository_is_in_sync_with_variants(self):
        self.assertEqual(generator.icon_sync_problems(), [])

    def test_names_derive_from_variants(self):
        names = generator.characters()
        self.assertEqual(names, list(generator.icon_builder.VARIANTS))
        self.assertEqual(generator.app_icon_name(names[0]), "AppIcon")
        self.assertEqual(generator.app_icon_name(names[1]), f"AppIcon-{names[1]}")
        self.assertEqual(generator.alternate_icon_setting().split(" "), [f"AppIcon-{name}" for name in names[1:]])
        self.assertEqual(generator.swift_catalog().count("AppIconChoice(name:"), len(names))

    def test_grain_and_corner_mask_are_the_only_changes_to_the_finished_icon(self):
        name = generator.characters()[0]
        with_grain = generator.icon_svg(name, grain=True)
        self.assertEqual(with_grain.count('filter="url(#grain)"'), 1)
        self.assertNotIn('filter="url(#grain)"', generator.icon_svg(name, grain=False))
        self.assertNotIn("clip-path", with_grain)
        masked = generator.icon_svg(name, grain=True, corner_mask=True)
        self.assertIn('rx="229.07"', masked)
        self.assertEqual(masked.count('<g clip-path="url(#corner)">'), 1)

    def test_a_changed_set_is_reported(self):
        second = generator.characters()[1]
        project = generator.PROJECT.read_text().replace(f"AppIcon-{second} ", "")
        self.assertTrue(any("project.pbxproj" in problem for problem in generator.icon_sync_problems(project_text=project)))
        swift = generator.swift_catalog().replace(f'AppIconChoice(name: "{second}", group: .people),\n', "")
        self.assertTrue(any("AppIconCatalog" in problem for problem in generator.icon_sync_problems(swift_text=swift)))
        strings = {generator.label_key("nobody"): {}}
        problems = generator.icon_sync_problems(strings=strings)
        self.assertTrue(any(f'"AppIcon.{second}" has no pt-BR label' in problem for problem in problems))
        self.assertTrue(any('"AppIcon.nobody" has no character' in problem for problem in problems))

    def test_every_app_icon_set_declares_default_dark_and_tinted(self):
        for character in generator.characters():
            name = generator.app_icon_name(character)
            images = generator.asset_contents(name, preview=False)["images"]
            self.assertEqual([image.get("appearances") for image in images],
                             [None, [{"appearance": "luminosity", "value": "dark"}],
                              [{"appearance": "luminosity", "value": "tinted"}]], name)
            self.assertEqual(len({image["filename"] for image in images}), 3, name)
            for image in images:
                self.assertEqual((image["idiom"], image["platform"], image["size"]), ("universal", "ios", "1024x1024"))
        preview = generator.asset_contents(generator.preview_name("swept"), preview=True)["images"]
        self.assertEqual(preview, [{"filename": "IconPreview-swept.png", "idiom": "universal"}])

    def test_a_set_without_all_three_appearances_is_reported(self):
        with tempfile.TemporaryDirectory() as scratch:
            catalog = pathlib.Path(scratch) / "Assets.xcassets"
            shutil.copytree(generator.CATALOG, catalog)
            # Only what the damage below adds is asserted, so unrelated drift in the repository fails
            # test_the_repository_is_in_sync_with_variants and not this test.
            before = generator.icon_sync_problems(catalog=catalog)
            (catalog / "AppIcon.appiconset/.DS_Store").write_bytes(b"")
            self.assertEqual(generator.icon_sync_problems(catalog=catalog), before)
            panda = catalog / "AppIcon-panda.appiconset"
            (panda / "AppIcon-panda.dark.png").unlink()
            contents = json.loads((panda / "Contents.json").read_text())
            contents["images"] = contents["images"][:1]  # what the set looked like before the appearances existed
            (panda / "Contents.json").write_text(json.dumps(contents))
            # A default image that carries alpha, and a dark one that does not, are both wrong.
            afro = catalog / "AppIcon-afro.appiconset"
            shutil.copy(afro / "AppIcon-afro.png", afro / "AppIcon-afro.tinted.png")
            (afro / "leftover.png").write_bytes(b"")
            (catalog / "AppIcon-bald.appiconset/AppIcon-bald.dark.png").write_bytes(b"")  # an interrupted render
            problems = [p for p in generator.icon_sync_problems(catalog=catalog) if p not in before]
        self.assertIn("missing AppIcon-panda.appiconset/AppIcon-panda.dark.png (the dark appearance)", problems)
        self.assertTrue(any(problem.startswith("AppIcon-panda.appiconset/Contents.json is not what the generator writes")
                            for problem in problems), problems)
        self.assertIn("AppIcon-afro.appiconset/AppIcon-afro.tinted.png must be 1024 px, RGBA", problems)
        self.assertIn("stale AppIcon-afro.appiconset/leftover.png", problems)
        self.assertIn("AppIcon-bald.appiconset/AppIcon-bald.dark.png must be 1024 px, RGBA", problems)
        self.assertEqual(len(problems), 5, problems)

    def test_dark_and_tinted_are_the_same_glyph_on_a_transparent_background(self):
        for character in ("swept", "glasses", "panda"):
            glyph = generator.icon_builder.glyph_defs(generator.character_spec(character))
            self.assertIn('<mask id="cut"', glyph)
            self.assertIn(glyph, generator.icon_svg(character))
            for appearance in ("dark", "tinted"):
                svg = generator.appearance_svg(character, appearance)
                self.assertIn(glyph, svg, f"{character} {appearance}: mark differs from the default icon")
                body = svg.split("</defs>")[1]
                self.assertNotIn("<rect", body)  # nothing painted behind the mark: cut-outs are real transparency
                self.assertNotIn("url(#shadow)", body)
        self.assertIn('fill="url(#field)"', generator.appearance_svg("swept", "dark", opaque_field=generator.DARK_FIELD))

    def test_the_tinted_mark_has_no_colour(self):
        for value in generator.APPEARANCE_MARKS["tinted"]:
            self.assertEqual(len({value[1:3], value[3:5], value[5:7]}), 1, value)
        colours = set(re.findall(r"#[0-9A-Fa-f]{6}", generator.appearance_svg("glasses", "tinted")))
        # The mark's two greys, plus the white and black of the cut-out mask.
        self.assertEqual(colours, set(generator.APPEARANCE_MARKS["tinted"]) | {"#FFFFFF", "#000000"})

    def test_project_update_needs_both_configurations(self):
        with self.assertRaises(SystemExit):
            generator.updated_project("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n")


if __name__ == "__main__":
    unittest.main()
