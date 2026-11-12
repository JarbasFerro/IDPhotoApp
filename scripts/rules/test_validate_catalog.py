#!/usr/bin/env python3
"""Tests for validate_catalog.py: the real catalog passes, and each class of error is caught.

Run: python3 -m unittest discover -s scripts/rules -p 'test_*.py'
"""
import copy
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import validate_catalog as vc  # noqa: E402

CATALOG = os.path.join(os.path.dirname(__file__), "..", "..", "Rules", "catalog", "v1")


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = os.path.join(self.tmp, "v1")
        shutil.copytree(CATALOG, self.root)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def mutate(self, profile_id, change):
        path = os.path.join(self.root, "profiles", f"{profile_id}.json")
        p = json.load(open(path, encoding="utf-8"))
        change(p)
        json.dump(p, open(path, "w", encoding="utf-8"))

    def errors(self):
        return vc.validate_catalog(self.root).errors

    def assertCaught(self, fragment):
        errs = self.errors()
        self.assertTrue(any(fragment in e for e in errs), f"expected '{fragment}' in {errs}")

    def test_real_catalog_is_valid(self):
        self.assertEqual(self.errors(), [])

    def test_min_greater_than_max(self):
        self.mutate("jp.passport.standard", lambda p: p["composition"]["headHeight"].update(minInclusive=40))
        self.assertCaught("min > max")

    def test_unknown_source_reference(self):
        self.mutate("us.passport.standard", lambda p: p["composition"]["headHeight"].update(sourceIds=["nope"]))
        self.assertCaught("unknown sourceId 'nope'")

    def test_official_profile_without_sources(self):
        self.mutate("kr.passport.standard", lambda p: p.update(sources=[]))
        self.assertCaught("at least one source")

    def test_missing_last_reviewed(self):
        self.mutate("es.national-id.dni", lambda p: p["effective"].update(lastReviewed=None))
        self.assertCaught("lastReviewed")

    def test_framing_target_outside_official_range(self):
        self.mutate("nl.passport.standard", lambda p: p["framingTarget"].update(headHeightPercent=80.0))
        self.assertCaught("outside official")

    def test_framing_target_infeasible_headroom(self):
        self.mutate("es.national-id.dni", lambda p: p["framingTarget"].update(headHeightPercent=90.0, eyeLineFromBottomPercent=62.0))
        self.assertCaught("headroom")

    def test_print_aspect_must_match_frame(self):
        self.mutate("it.national-id.cie", lambda p: p["outputs"][0].update(physicalWidthMm=40))
        self.assertCaught("aspect differs")

    def test_digital_profile_composition_aspect(self):
        self.mutate("us.passport.standard", lambda p: p["outputs"][1].update(pixelWidth=1000))
        self.assertCaught("aspect ratio")

    def test_pixel_limits(self):
        self.mutate("us.visa.standard", lambda p: p["outputs"][0].update(pixelWidth=1300, pixelHeight=1300))
        self.assertCaught("above pixelLimits")

    def test_unsupported_format(self):
        self.mutate("jp.national-id.mynumber", lambda p: p["outputs"][1].update(formats=["heic"]))
        self.assertCaught("unsupported output format")

    def test_machine_hard_without_evaluator(self):
        self.mutate("kr.passport.standard", lambda p: p["composition"]["headHeight"].update(capability="machine_hard"))
        self.assertCaught("machine_hard without")

    def test_unsupported_landmark(self):
        self.mutate("it.national-id.cie", lambda p: p["composition"]["headHeight"].update(landmarks=["forehead", "chin"]))
        self.assertCaught("unsupported landmark")

    def test_missing_localization_key(self):
        self.mutate("au.passport.standard", lambda p: p["checks"].append({"id": "made-up", "capability": "manual", "sourceIds": ["au-passports-photos"]}))
        self.assertCaught("localization key missing")

    def test_special_case_targets_unknown_check(self):
        self.mutate("gb.passport.standard", lambda p: p["specialCases"][0]["overrides"][0].update(target="check:ghost"))
        self.assertCaught("unknown check 'ghost'")

    def test_ppi_below_300(self):
        self.mutate("nl.passport.standard", lambda p: p["outputs"][0].update(minPpi=200, preferredPpi=200))
        self.assertCaught("minPpi")

    def test_catalog_index_must_match_files(self):
        os.remove(os.path.join(self.root, "profiles", "ca.visa.visitor.json"))
        self.assertCaught("lists 'ca.visa.visitor' but no file exists")

    def test_file_name_must_match_id(self):
        src = os.path.join(self.root, "profiles", "ca.visa.visitor.json")
        p = json.load(open(src))
        p2 = copy.deepcopy(p)
        p2["profileId"] = "ca.visa.other"
        json.dump(p2, open(src, "w"))
        self.assertCaught("file name must equal profileId")

    def set_region_default(self, region, profile_id):
        path = os.path.join(self.root, "catalog.json")
        c = json.load(open(path))
        c["regionDefaults"][region] = profile_id
        json.dump(c, open(path, "w"))

    def test_region_default_must_exist(self):
        self.set_region_default("FR", "fr.passport.standard")
        self.assertCaught("unknown profile 'fr.passport.standard'")

    def test_region_default_must_be_that_countrys_profile(self):
        self.set_region_default("CA", "us.visa.standard")
        self.assertCaught("must be a profile of that country")

    def test_bad_replacement_colour(self):
        self.mutate("schengen.visa.standard", lambda p: p["background"].update(replacementColor="white"))
        self.assertCaught("replacementColor")


if __name__ == "__main__":
    unittest.main()
