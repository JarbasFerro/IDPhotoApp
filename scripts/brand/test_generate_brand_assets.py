#!/usr/bin/env python3
"""Unit tests for generate-brand-assets.py: the fill-role contrast logic and the choose-your-icon sync check
(stdlib only; writes nothing, renders nothing).

Run: python3 scripts/brand/test_generate_brand_assets.py
"""
import colorsys
import importlib.util
import pathlib
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

    def test_project_update_needs_both_configurations(self):
        with self.assertRaises(SystemExit):
            generator.updated_project("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n")


if __name__ == "__main__":
    unittest.main()
