#!/usr/bin/env python3
"""Validate the Calipic profile catalog (docs/05-rules-engine.md §12).

Structural and semantic checks; no third-party dependencies. Exit code 1 on any error.

Usage: python3 scripts/rules/validate_catalog.py [Rules/catalog/v1]
"""
import json
import os
import re
import sys
from datetime import date

ID_RE = re.compile(r"^[a-z]{2,}(\.[a-z0-9-]+){2}$")
HEX_RE = re.compile(r"^#[0-9A-F]{6}$")
DOC_TYPES = {"passport", "national_id", "residence_permit", "driving_licence", "visa", "other"}
CAPABILITIES = {"machine_hard", "machine_advisory", "manual", "informational", "unsupported"}
# machine_hard needs a calibrated evaluator (AGENTS.md §9). None are registered yet.
HARD_EVALUATORS = set()
LANDMARKS = {"crown", "top_of_hair", "chin", "eye_line", "bottom_edge", "ear_base"}
UNITS = {"mm", "percent_output_height"}
APPEARANCES = {"white", "white_or_off_white", "light", "plain", "specified_colors"}
EDITING_RULES = {"allowed", "disallowed", "discouraged", "unknown"}
UNIFORMITY = {"required", "recommended", "unspecified"}
SHADOWS = {"forbidden", "discouraged", "unspecified"}
SOURCE_TYPES = {"official", "delegated_authority", "authoritative_secondary"}
FORMATS = {"jpeg", "png"}
ROUTES = {"home", "shop_only"}
COMPOSITION_MODES = {"profile", "loose"}
FRAMING_BASES = {"official_midpoint", "app_default"}
# Anthropometric model shared with the spike (FaceGeometry.swift: crown-to-chin = 1.8 × eye-to-chin).
CROWN_TO_EYE_FRACTION = 0.8 / 1.8
MIN_HEADROOM_PERCENT = 4.0
ASPECT_TOLERANCE = 0.005


class Report:
    def __init__(self):
        self.errors = []

    def err(self, where, message):
        self.errors.append(f"{where}: {message}")


def is_date(value):
    try:
        date.fromisoformat(value)
        return True
    except (TypeError, ValueError):
        return False


def number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def constraint_percent(c, frame_height):
    """Return (min, max) of a composition constraint as percent of output height, or None."""
    lo, hi = c.get("minInclusive"), c.get("maxInclusive")
    if c.get("unit") == "percent_output_height":
        return lo, hi
    if frame_height:
        return 100 * lo / frame_height, 100 * hi / frame_height
    return None


def check_constraint(r, where, c, known_sources, frame):
    if c is None:
        return
    for key in ("landmarks", "unit", "minInclusive", "maxInclusive", "capability", "sourceIds"):
        if key not in c:
            r.err(where, f"missing '{key}'")
            return
    if not (isinstance(c["landmarks"], list) and len(c["landmarks"]) == 2 and set(c["landmarks"]) <= LANDMARKS):
        r.err(where, f"unsupported landmark semantics {c['landmarks']}")
    if c["unit"] not in UNITS:
        r.err(where, f"unit '{c['unit']}'")
    if not (number(c["minInclusive"]) and number(c["maxInclusive"])):
        r.err(where, "min/max must be numbers")
        return
    if c["minInclusive"] > c["maxInclusive"]:
        r.err(where, "min > max")
    if c["unit"] == "mm":
        if not frame:
            r.err(where, "mm constraint without referenceFrameMm")
        elif c["maxInclusive"] > frame["height"]:
            r.err(where, "mm constraint larger than the frame height")
    if c["unit"] == "percent_output_height" and not (0 <= c["minInclusive"] <= c["maxInclusive"] <= 100):
        r.err(where, "percent outside 0–100")
    check_capability(r, where, c["capability"])
    check_source_refs(r, where, c["sourceIds"], known_sources)


def check_capability(r, where, cap):
    if cap not in CAPABILITIES:
        r.err(where, f"capability '{cap}'")
    elif cap == "machine_hard" and where not in HARD_EVALUATORS:
        r.err(where, "machine_hard without a registered calibrated evaluator")


def check_source_refs(r, where, ids, known):
    if not isinstance(ids, list) or not ids:
        r.err(where, "needs at least one sourceId")
        return
    for sid in ids:
        if sid not in known:
            r.err(where, f"unknown sourceId '{sid}'")


def aspect(w, h):
    return w / h


def validate_profile(r, path, p, strings):
    pid = p.get("profileId", "?")
    w = pid
    for key in ("schemaVersion", "profileId", "profileVersion", "status", "kind", "jurisdiction", "document", "effective",
                "referenceFrameMm", "outputs", "composition", "framingTarget", "background", "recencyMonths", "checks",
                "specialCases", "profileQuestions", "sources", "notes"):
        if key not in p:
            r.err(w, f"missing '{key}'")
    if r.errors and any(e.startswith(f"{w}: missing") for e in r.errors):
        return
    if p["schemaVersion"] != 1:
        r.err(w, "schemaVersion must be 1")
    if not ID_RE.match(pid):
        r.err(w, "profileId must be '<jurisdiction>.<document>.<variant>' in lowercase")
    if os.path.basename(path) != f"{pid}.json":
        r.err(w, "file name must equal profileId")
    if not re.match(r"^\d+\.\d+\.\d+$", p["profileVersion"]):
        r.err(w, "profileVersion must be semantic (x.y.z)")
    if p["status"] not in {"active", "draft", "retired"} or p["kind"] != "official":
        r.err(w, "status/kind")

    j = p["jurisdiction"]
    if not (j.get("countryCode") or j.get("regionCode")):
        r.err(w, "jurisdiction needs countryCode or regionCode")
    if j.get("countryCode") and not re.match(r"^[A-Z]{2}$", j["countryCode"]):
        r.err(w, "countryCode must be ISO 3166-1 alpha-2")
    if j.get("countryCode") and not pid.startswith(j["countryCode"].lower() + "."):
        r.err(w, "profileId must start with the country code")

    d = p["document"]
    if d.get("type") not in DOC_TYPES:
        r.err(w, f"document.type '{d.get('type')}'")
    if d.get("nameKey") not in strings:
        r.err(w, f"localization key missing: {d.get('nameKey')}")

    e = p["effective"]
    if not is_date(e.get("lastReviewed")):
        r.err(w, "effective.lastReviewed missing or not ISO date")
    if e.get("from") and e.get("to") and e["to"] < e["from"]:
        r.err(w, "effective.to earlier than effective.from")

    sources = p["sources"]
    known = set()
    if not sources:
        r.err(w, "official profile needs at least one source")
    for s in sources:
        sid = s.get("sourceId")
        if sid in known:
            r.err(w, f"duplicate sourceId '{sid}'")
        known.add(sid)
        for key in ("authorityName", "title", "url", "accessedDate", "language", "sourceType"):
            if not s.get(key):
                r.err(w, f"source '{sid}' missing '{key}'")
        if s.get("sourceType") not in SOURCE_TYPES:
            r.err(w, f"source '{sid}' sourceType")
        if not str(s.get("url", "")).startswith("https://"):
            r.err(w, f"source '{sid}' url must be https")
        if not is_date(s.get("accessedDate")):
            r.err(w, f"source '{sid}' accessedDate")

    frame = p["referenceFrameMm"]
    if frame is not None and not (number(frame.get("width")) and number(frame.get("height")) and frame["width"] > 0 and frame["height"] > 0):
        r.err(w, "referenceFrameMm needs positive width and height")
        frame = None

    outputs = p["outputs"]
    if not outputs:
        r.err(w, "needs at least one output")
    ids = set()
    frame_aspect = aspect(frame["width"], frame["height"]) if frame else None
    for o in outputs:
        ow = f"{w} output '{o.get('id')}'"
        if o.get("id") in ids:
            r.err(ow, "duplicate output id")
        ids.add(o.get("id"))
        if o.get("kind") == "print":
            if not (number(o.get("physicalWidthMm")) and number(o.get("physicalHeightMm"))):
                r.err(ow, "print needs physical width and height")
                continue
            if frame_aspect and abs(aspect(o["physicalWidthMm"], o["physicalHeightMm"]) - frame_aspect) > ASPECT_TOLERANCE:
                r.err(ow, "print aspect differs from referenceFrameMm")
            if not (number(o.get("minPpi")) and number(o.get("preferredPpi")) and 300 <= o["minPpi"] <= o["preferredPpi"]):
                r.err(ow, "minPpi must be ≥ 300 and ≤ preferredPpi")
            if o.get("route") not in ROUTES:
                r.err(ow, f"route '{o.get('route')}'")
            if o.get("noteKey") and o["noteKey"] not in strings:
                r.err(ow, f"localization key missing: {o['noteKey']}")
        elif o.get("kind") == "digital":
            pw, ph = o.get("pixelWidth"), o.get("pixelHeight")
            if not (isinstance(pw, int) and isinstance(ph, int) and pw > 0 and ph > 0):
                r.err(ow, "digital needs integer pixel width and height")
                continue
            if not o.get("formats") or not set(o["formats"]) <= FORMATS:
                r.err(ow, f"unsupported output format {o.get('formats')}")
            fs = o.get("fileSizeBytes") or {}
            if fs.get("max") is not None and fs.get("min") is not None and fs["min"] > fs["max"]:
                r.err(ow, "fileSizeBytes min > max")
            if o.get("colorSpace") != "srgb":
                r.err(ow, "colorSpace must be srgb")
            if o.get("composition") not in COMPOSITION_MODES:
                r.err(ow, "composition must be 'profile' or 'loose'")
            if o.get("composition") == "profile" and frame_aspect and abs(aspect(pw, ph) - frame_aspect) > ASPECT_TOLERANCE:
                r.err(ow, "composition 'profile' requires the frame's aspect ratio")
            lim = o.get("pixelLimits") or {}
            if lim.get("minWidth") and pw < lim["minWidth"] or lim.get("minHeight") and ph < lim["minHeight"]:
                r.err(ow, "pixel size below pixelLimits minimum")
            if lim.get("maxWidth") and pw > lim["maxWidth"] or lim.get("maxHeight") and ph > lim["maxHeight"]:
                r.err(ow, "pixel size above pixelLimits maximum")
            if lim.get("square") and pw != ph:
                r.err(ow, "pixelLimits.square but output is not square")
        else:
            r.err(ow, f"kind '{o.get('kind')}'")

    comp = p["composition"]
    frame_h = frame["height"] if frame else None
    for name in ("headHeight", "eyeLine", "faceWidth"):
        check_constraint(r, f"{w} composition.{name}", comp.get(name), known, frame)
    eye = comp.get("eyeLine")
    if eye and eye.get("landmarks") != ["bottom_edge", "eye_line"]:
        r.err(f"{w} composition.eyeLine", "landmarks must be [bottom_edge, eye_line]")
    face = comp.get("faceWidth")
    if face and face.get("unit") != "mm":
        r.err(f"{w} composition.faceWidth", "must be in mm")

    ft = p["framingTarget"]
    head_t, eye_t = ft.get("headHeightPercent"), ft.get("eyeLineFromBottomPercent")
    if ft.get("basis") not in FRAMING_BASES or not (number(head_t) and number(eye_t)):
        r.err(w, "framingTarget needs basis, headHeightPercent and eyeLineFromBottomPercent")
    else:
        head = comp.get("headHeight")
        rng = constraint_percent(head, frame_h) if head else None
        if rng and not (rng[0] - 1e-9 <= head_t <= rng[1] + 1e-9):
            r.err(w, f"framingTarget head {head_t} % outside official {rng[0]:.1f}–{rng[1]:.1f} %")
        rng = constraint_percent(eye, frame_h) if eye else None
        if rng and not (rng[0] - 1e-9 <= eye_t <= rng[1] + 1e-9):
            r.err(w, f"framingTarget eye line {eye_t} % outside official {rng[0]:.1f}–{rng[1]:.1f} %")
        headroom = (100 - eye_t) - CROWN_TO_EYE_FRACTION * head_t
        chin = eye_t - (1 - CROWN_TO_EYE_FRACTION) * head_t
        if headroom < MIN_HEADROOM_PERCENT:
            r.err(w, f"framingTarget infeasible: headroom {headroom:.1f} % < {MIN_HEADROOM_PERCENT} %")
        if chin < 0:
            r.err(w, "framingTarget infeasible: chin below the bottom edge")
        if ft["basis"] == "official_midpoint" and not head and not eye:
            r.err(w, "framingTarget basis official_midpoint but no official composition")

    b = p["background"]
    bw = f"{w} background"
    if b.get("requiredAppearance") not in APPEARANCES:
        r.err(bw, f"requiredAppearance '{b.get('requiredAppearance')}'")
    if b.get("requiredAppearance") == "specified_colors" and not b.get("allowedColors"):
        r.err(bw, "specified_colors needs allowedColors")
    if not HEX_RE.match(str(b.get("replacementColor"))):
        r.err(bw, "replacementColor must be #RRGGBB (uppercase)")
    if b.get("officialEditingRule") not in EDITING_RULES:
        r.err(bw, "officialEditingRule")
    if b.get("uniformity") not in UNIFORMITY or b.get("shadows") not in SHADOWS:
        r.err(bw, "uniformity/shadows")
    check_capability(r, bw, b.get("capability"))
    check_source_refs(r, bw, b.get("sourceIds"), known)

    rec = p["recencyMonths"]
    if rec is not None and not (isinstance(rec, int) and 0 < rec <= 24):
        r.err(w, "recencyMonths must be null or 1–24")

    check_ids = set()
    for c in p["checks"]:
        cw = f"{w} check '{c.get('id')}'"
        if c.get("id") in check_ids:
            r.err(cw, "duplicate check")
        check_ids.add(c.get("id"))
        if f"check.{c.get('id')}" not in strings:
            r.err(cw, "localization key missing")
        check_capability(r, cw, c.get("capability"))
        check_source_refs(r, cw, c.get("sourceIds"), known)

    for s in p["specialCases"]:
        sw = f"{w} specialCase '{s.get('id')}'"
        cond = s.get("condition") or {}
        if cond.get("type") not in {"age_lt", "age_lte"} or not isinstance(cond.get("years"), int):
            r.err(sw, "condition must be age_lt/age_lte with integer years")
        check_source_refs(r, sw, s.get("sourceIds"), known)
        for ov in s.get("overrides") or []:
            target = ov.get("target", "")
            if target.startswith("check:"):
                if target[6:] not in check_ids:
                    r.err(sw, f"override targets unknown check '{target[6:]}'")
                if "capability" in ov:
                    check_capability(r, sw, ov["capability"])
            elif target.startswith("composition."):
                base = comp.get(target.split(".", 1)[1])
                if not base:
                    r.err(sw, f"override targets missing {target}")
                elif ov.get("minInclusive", 0) > ov.get("maxInclusive", 0):
                    r.err(sw, "override min > max")
            else:
                r.err(sw, f"override target '{target}'")
        if not s.get("overrides"):
            r.err(sw, "needs overrides")

    if not isinstance(p["notes"], list) or not isinstance(p["profileQuestions"], list):
        r.err(w, "notes and profileQuestions must be lists")


def validate_catalog(root):
    r = Report()
    try:
        catalog = json.load(open(os.path.join(root, "catalog.json"), encoding="utf-8"))
        strings = json.load(open(os.path.join(root, "strings.en.json"), encoding="utf-8"))
        shortcuts = json.load(open(os.path.join(root, "custom-size-shortcuts.json"), encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        r.err(root, f"cannot read catalog files: {error}")
        return r
    profile_dir = os.path.join(root, "profiles")
    files = sorted(f for f in os.listdir(profile_dir) if f.endswith(".json"))
    seen = set()
    for name in files:
        path = os.path.join(profile_dir, name)
        try:
            p = json.load(open(path, encoding="utf-8"))
        except json.JSONDecodeError as error:
            r.err(name, f"invalid JSON: {error}")
            continue
        key = (p.get("profileId"), p.get("profileVersion"))
        if key in seen:
            r.err(name, "duplicate profileId/version")
        seen.add(key)
        validate_profile(r, path, p, strings)
    listed = set(catalog.get("profiles", []))
    on_disk = {f[:-5] for f in files}
    for missing in sorted(listed - on_disk):
        r.err("catalog.json", f"lists '{missing}' but no file exists")
    for extra in sorted(on_disk - listed):
        r.err("catalog.json", f"'{extra}' exists but is not listed")
    # The document a new user in a region starts on. Only a profile of that same country may be a default:
    # visa profiles serve people outside the issuing country and are never a regional default.
    countries = {}
    for name in files:
        try:
            p = json.load(open(os.path.join(profile_dir, name), encoding="utf-8"))
            countries[p.get("profileId")] = (p.get("jurisdiction") or {}).get("countryCode")
        except json.JSONDecodeError:
            pass
    for region, pid in (catalog.get("regionDefaults") or {}).items():
        if not re.match(r"^[A-Z]{2}$", region):
            r.err("catalog.json", f"regionDefaults key '{region}' must be ISO 3166-1 alpha-2")
        if pid not in on_disk:
            r.err("catalog.json", f"regionDefaults['{region}'] names unknown profile '{pid}'")
        elif countries.get(pid) != region:
            r.err("catalog.json", f"regionDefaults['{region}'] must be a profile of that country, not '{pid}'")
    for s in shortcuts.get("shortcuts", []):
        sw = f"shortcut '{s.get('id')}'"
        if not (number(s.get("widthMm")) and number(s.get("heightMm")) and s["widthMm"] > 0 and s["heightMm"] > 0):
            r.err(sw, "needs positive widthMm and heightMm")
        for key in [s.get("nameKey")] + list((s.get("localeNameKeys") or {}).values()):
            if key not in strings:
                r.err(sw, f"localization key missing: {key}")
    return r


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "Rules", "catalog", "v1")
    report = validate_catalog(root)
    if report.errors:
        print("\n".join(report.errors))
        print(f"FAILED: {len(report.errors)} error(s)")
        sys.exit(1)
    count = len([f for f in os.listdir(os.path.join(root, "profiles")) if f.endswith(".json")])
    print(f"OK: {count} profiles valid")


if __name__ == "__main__":
    main()
