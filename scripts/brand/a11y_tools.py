#!/usr/bin/env python3
"""Calipic brand - accessibility & perception tooling (python3 stdlib only).

Helper for scripts/brand/render-a11y.sh. Subcommands:

  selftest                          sanity-check the colour math against known values
  build <icon.svg> <dir> <label>    write sheet/strip/probe SVGs + manifest.tsv into <dir>
  tables <out.md>                   write the generated WCAG / CIEDE2000 tables fragment
  inject <doc.md> <fragment.md>     replace the generated block inside the doc
  verify-probe <png> <sim>          decode probe PNG, compare filter output with computed values
  verify-gray <bmp>                 assert a rendered image (converted to BMP) has no chroma

All palette values are PROVISIONAL TEST VALUES, not brand decisions (BD-033 is open).
The icon is a draft stand-in; only three colour tokens are substituted, geometry is untouched.
"""
import math
import os
import re
import struct
import sys
import zlib

# --------------------------------------------------------------------------------------
# Palette (provisional test values shared by the colour-evidence work units)
# --------------------------------------------------------------------------------------

CANDIDATES = [
    # id, name, accent values per appearance
    ("A", "Deep blue",
     {"light": "#1F3FA8", "dark": "#7C98F5", "ic_light": "#142C7A", "ic_dark": "#A9BCFF"}),
    ("B", "Dark cyan / blue-teal",
     {"light": "#0E6F7C", "dark": "#4FC3D1", "ic_light": "#084C55", "ic_dark": "#8ADFE9"}),
    ("C", "Graphite + cool accent",
     {"light": "#5B7C99", "dark": "#9DB7CF", "ic_light": "#3D5A73", "ic_dark": "#C3D6E6"}),
    ("D", "Warm challenger (amber-ochre)",
     {"light": "#B26A00", "dark": "#F0B55A", "ic_light": "#7A4800", "ic_dark": "#FFD08A"}),
]
C_INK = {"light": "#1C1F24", "dark": "#F2F3F5", "ic_light": "#1C1F24", "ic_dark": "#F2F3F5"}

DARK_FIELD = "#111214"
DARK_FIELD_STROKE = "#2C2D31"
LIGHT_FIELD_STROKE = "#D9D9D9"

# iOS system colours. Default values as given in the unit brief; the Increase-Contrast
# ("accessible") values are the ones published in Apple's HIG colour table - verify on device.
SYSTEM = {
    "light":    {"green": "#34C759", "orange": "#FF9500", "red": "#FF3B30", "blue": "#007AFF", "gray": "#8E8E93"},
    "dark":     {"green": "#30D158", "orange": "#FF9F0A", "red": "#FF453A", "blue": "#0A84FF", "gray": "#8E8E93"},
    "ic_light": {"green": "#248A3D", "orange": "#C93400", "red": "#D70015", "blue": "#0040DD", "gray": "#6C6C70"},
    "ic_dark":  {"green": "#30DB5B", "orange": "#FFB340", "red": "#FF6961", "blue": "#409CFF", "gray": "#AEAEB2"},
}
STATUS_ROLE = {"green": "pass", "orange": "warn", "red": "fail", "gray": "manual_check", "blue": "system tint/info"}
STATUS_ORDER = ["green", "orange", "red", "gray", "blue"]

BACKGROUNDS = {
    "light": ["#FFFFFF", "#F2F2F7"], "ic_light": ["#FFFFFF", "#F2F2F7"],
    "dark": ["#000000", "#1C1C1E"], "ic_dark": ["#000000", "#1C1C1E"],
}
MODES = ["light", "dark", "ic_light", "ic_dark"]
MODE_LABEL = {"light": "Light", "dark": "Dark", "ic_light": "Increase Contrast - Light",
              "ic_dark": "Increase Contrast - Dark"}

# --------------------------------------------------------------------------------------
# Simulation matrices
# --------------------------------------------------------------------------------------
# Machado, Oliveira & Fernandes (2009), "A Physiologically-based Model for Simulation of
# Color Vision Deficiency", IEEE TVCG 15(6) - severity 1.0 (dichromacy). Defined for LINEAR RGB.
# Grayscale = relative luminance Y (Rec.709 / sRGB primaries), also in linear RGB.
MATRICES = {
    "protanopia": [
        [0.152286, 1.052583, -0.204868],
        [0.114503, 0.786281, 0.099216],
        [-0.003882, -0.048116, 1.051998],
    ],
    "deuteranopia": [
        [0.367322, 0.860646, -0.227968],
        [0.280085, 0.672501, 0.047413],
        [-0.011820, 0.042940, 0.968881],
    ],
    "tritanopia": [
        [1.255528, -0.076749, -0.178779],
        [-0.078411, 0.930809, 0.147602],
        [0.004733, 0.691367, 0.303900],
    ],
    "grayscale": [
        [0.2126, 0.7152, 0.0722],
        [0.2126, 0.7152, 0.0722],
        [0.2126, 0.7152, 0.0722],
    ],
}
SIMS = ["normal", "grayscale", "protanopia", "deuteranopia", "tritanopia"]
COLOUR_SIMS = [s for s in SIMS if s != "grayscale"]
SIM_LABEL = {
    "normal": "Normal vision (no filter)",
    "grayscale": "Grayscale (relative luminance)",
    "protanopia": "Protanopia (Machado 2009, severity 1.0)",
    "deuteranopia": "Deuteranopia (Machado 2009, severity 1.0)",
    "tritanopia": "Tritanopia (Machado 2009, severity 1.0)",
}

# --------------------------------------------------------------------------------------
# Colour math
# --------------------------------------------------------------------------------------


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#%02X%02X%02X" % tuple(rgb)


def srgb_to_linear(c8):
    c = c8 / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb8(v):
    v = min(1.0, max(0.0, v))
    c = v * 12.92 if v <= 0.0031308 else 1.055 * (v ** (1 / 2.4)) - 0.055
    return int(round(min(1.0, max(0.0, c)) * 255))


def simulate(hex_color, sim):
    """Apply a simulation matrix in linear RGB (same maths as the SVG filter)."""
    if sim == "normal":
        return hex_color.upper()
    m = MATRICES[sim]
    lin = [srgb_to_linear(c) for c in hex_to_rgb(hex_color)]
    out = [sum(m[r][k] * lin[k] for k in range(3)) for r in range(3)]
    return rgb_to_hex([linear_to_srgb8(v) for v in out])


def rel_luminance(hex_color):
    r, g, b = (srgb_to_linear(c) for c in hex_to_rgb(hex_color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(h1, h2):
    l1, l2 = rel_luminance(h1), rel_luminance(h2)
    if l1 < l2:
        l1, l2 = l2, l1
    return (l1 + 0.05) / (l2 + 0.05)


def hex_to_lab(hex_color):
    r, g, b = (srgb_to_linear(c) for c in hex_to_rgb(hex_color))
    x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    xn, yn, zn = 0.95047, 1.0, 1.08883  # D65

    def f(t):
        return t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116

    fx, fy, fz = f(x / xn), f(y / yn), f(z / zn)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def lab_to_hex(lab):
    L, a, b = lab
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200

    def finv(t):
        return t ** 3 if t ** 3 > 216 / 24389 else (116 * t - 16) / (24389 / 27)

    x, y, z = 0.95047 * finv(fx), 1.0 * finv(fy), 1.08883 * finv(fz)
    r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    bb = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    return rgb_to_hex([linear_to_srgb8(v) for v in (r, g, bb)])


def ciede2000(lab1, lab2):
    """CIEDE2000 colour difference (Sharma, Wu & Dalal 2005 formulation), kL=kC=kH=1."""
    L1, a1, b1 = lab1
    L2, a2, b2 = lab2
    C1, C2 = math.hypot(a1, b1), math.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cm ** 7 / (Cm ** 7 + 25.0 ** 7)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)

    def hp(bv, ap):
        if bv == 0 and ap == 0:
            return 0.0
        return math.degrees(math.atan2(bv, ap)) % 360

    h1p, h2p = hp(b1, a1p), hp(b2, a2p)
    dLp = L2 - L1
    dCp = C2p - C1p
    if C1p * C2p == 0:
        dhp = 0.0
    elif abs(h2p - h1p) <= 180:
        dhp = h2p - h1p
    elif h2p - h1p > 180:
        dhp = h2p - h1p - 360
    else:
        dhp = h2p - h1p + 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp / 2))
    Lpm = (L1 + L2) / 2
    Cpm = (C1p + C2p) / 2
    if C1p * C2p == 0:
        hpm = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hpm = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        hpm = (h1p + h2p + 360) / 2
    else:
        hpm = (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hpm - 30)) + 0.24 * math.cos(math.radians(2 * hpm))
         + 0.32 * math.cos(math.radians(3 * hpm + 6)) - 0.20 * math.cos(math.radians(4 * hpm - 63)))
    dtheta = 30 * math.exp(-(((hpm - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cpm ** 7 / (Cpm ** 7 + 25.0 ** 7))
    Sl = 1 + 0.015 * (Lpm - 50) ** 2 / math.sqrt(20 + (Lpm - 50) ** 2)
    Sc = 1 + 0.045 * Cpm
    Sh = 1 + 0.015 * Cpm * T
    Rt = -math.sin(math.radians(2 * dtheta)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2
                     + Rt * (dCp / Sc) * (dHp / Sh))


def delta_e(h1, h2, sim="normal"):
    return ciede2000(hex_to_lab(simulate(h1, sim)), hex_to_lab(simulate(h2, sim)))


def delta_e76(h1, h2, sim="normal"):
    l1, l2 = hex_to_lab(simulate(h1, sim)), hex_to_lab(simulate(h2, sim))
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(l1, l2)))


def min_cell(c1, c2):
    """Flagged minimum dE00 over the colour simulations, with the CIE76 value of that same pair/sim."""
    v, s = min((delta_e(c1, c2, s), s) for s in COLOUR_SIMS)
    return "%s (dE76 %.0f)" % (flag_de(v), delta_e76(c1, c2, s))


def adjust_for_contrast(hex_color, backgrounds, target=4.5, direction=None):
    """Minimal CIELAB L* shift (a*, b* held) that reaches `target` against every background.

    Returns the original value if it already passes, or None if no in-gamut-ish value passes.
    """
    if all(contrast(hex_color, bg) >= target for bg in backgrounds):
        return hex_color.upper()
    L, a, b = hex_to_lab(hex_color)
    if direction is None:
        direction = -1 if rel_luminance(backgrounds[0]) > 0.5 else 1
    step = 0.25
    Lc = L
    while 0 <= Lc + direction * step <= 100:
        Lc += direction * step
        cand = lab_to_hex((Lc, a, b))
        if all(contrast(cand, bg) >= target for bg in backgrounds):
            return cand
    return None


def selftest():
    checks = []

    def check(name, got, want, tol):
        ok = abs(got - want) <= tol
        checks.append(ok)
        print("  %-52s got %8.4f  want %8.4f  %s" % (name, got, want, "ok" if ok else "MISMATCH"))

    check("contrast #FFFFFF vs #000000", contrast("#FFFFFF", "#000000"), 21.0, 0.001)
    check("contrast #007AFF vs #FFFFFF", contrast("#007AFF", "#FFFFFF"), 4.02, 0.03)
    check("contrast #777777 vs #FFFFFF", contrast("#777777", "#FFFFFF"), 4.48, 0.01)
    # Sharma et al. CIEDE2000 test data, pairs 1, 17 and 25.
    check("CIEDE2000 Sharma pair 1", ciede2000((50, 2.6772, -79.7751), (50, 0, -82.7485)), 2.0425, 0.0001)
    check("CIEDE2000 Sharma pair 17", ciede2000((50, 2.5, 0), (73, 25, -18)), 27.1492, 0.0001)
    check("CIEDE2000 Sharma pair 25", ciede2000((60.2574, -34.0099, 36.2677), (60.4626, -34.1751, 39.4387)),
          1.2644, 0.0001)
    lab_w = hex_to_lab("#FFFFFF")
    check("Lab L* of white", lab_w[0], 100.0, 0.01)
    check("Lab chroma of white", math.hypot(lab_w[1], lab_w[2]), 0.0, 0.02)
    for sim in MATRICES:
        for row in MATRICES[sim]:
            check("%s row sums to 1 (white preserved)" % sim, sum(row), 1.0, 0.0001)
    rt = lab_to_hex(hex_to_lab("#0E6F7C"))
    check("Lab round-trip #0E6F7C (channel error)",
          max(abs(x - y) for x, y in zip(hex_to_rgb(rt), hex_to_rgb("#0E6F7C"))), 0, 1)
    g = hex_to_rgb(simulate("#1F3FA8", "grayscale"))
    check("grayscale output is neutral", max(g) - min(g), 0, 0)
    if not all(checks):
        sys.exit("selftest FAILED")
    print("selftest passed (%d checks)" % len(checks))


# --------------------------------------------------------------------------------------
# SVG construction
# --------------------------------------------------------------------------------------

FONT = "font-family=\"Helvetica Neue, Helvetica, Arial, sans-serif\""
TOKEN_MARK, TOKEN_FIELD, TOKEN_STROKE = "#111111", "#FFFFFF", "#D9D9D9"


def load_icon(path):
    src = open(path, encoding="utf-8").read()
    missing = [t for t in (TOKEN_MARK, TOKEN_FIELD, TOKEN_STROKE) if t.lower() not in src.lower()]
    if missing:
        sys.exit("error: %s does not contain the recolour token(s) %s. The icon must use %s (mark), "
                 "%s (field + hair-strand cutout) and %s (field stroke)."
                 % (path, ", ".join(missing), TOKEN_MARK, TOKEN_FIELD, TOKEN_STROKE))
    m = re.search(r"<svg\b[^>]*>", src, re.S)
    end = src.rfind("</svg>")
    if not m or end < 0:
        sys.exit("error: %s is not an SVG document" % path)
    if not re.search(r'\bviewBox\s*=', m.group(0)):
        sys.exit("error: %s root <svg> needs a viewBox" % path)
    # Keep the root element's attributes (viewBox, presentation attributes such as fill="none", extra
    # namespace declarations) on the nested <svg>; drop only placement/identity attributes.
    drop = {"x", "y", "width", "height", "xmlns", "id", "role", "aria-labelledby", "aria-label", "version"}
    root_attrs = " ".join(
        '%s="%s"' % (k, v) for k, v in re.findall(r'([\w:.-]+)\s*=\s*"([^"]*)"', m.group(0)) if k not in drop)
    inner = src[m.end():end]
    inner = re.sub(r"<title\b.*?</title>", "", inner, flags=re.S)
    inner = re.sub(r"<desc\b.*?</desc>", "", inner, flags=re.S)
    inner = re.sub(r"<!--.*?-->", "", inner, flags=re.S)
    return root_attrs, inner


_instance = [0]


def uniquify_ids(inner):
    """Suffix every id (and its url(#..)/href references) so repeated, differently recoloured copies of an
    icon with <defs> (gradients, clip paths, shadows) do not resolve to the first copy on the page."""
    ids = set(re.findall(r'\bid\s*=\s*"([^"]+)"', inner))
    if not ids:
        return inner
    _instance[0] += 1
    sfx = "-i%d" % _instance[0]
    pat = "|".join(re.escape(i) for i in sorted(ids, key=len, reverse=True))
    inner = re.sub(r'\bid\s*=\s*"(%s)"' % pat, lambda m: 'id="%s%s"' % (m.group(1), sfx), inner)
    inner = re.sub(r'url\(\s*#(%s)\s*\)' % pat, lambda m: "url(#%s%s)" % (m.group(1), sfx), inner)
    inner = re.sub(r'href\s*=\s*"#(%s)"' % pat, lambda m: 'href="#%s%s"' % (m.group(1), sfx), inner)
    return inner


def recolor(inner, mark, field, stroke):
    """Substitute only the three colour tokens. Geometry is never touched."""
    table = {TOKEN_MARK.lower(): mark, TOKEN_FIELD.lower(): field, TOKEN_STROKE.lower(): stroke}
    return re.sub(r"#(?:111111|ffffff|d9d9d9)\b", lambda m: table[m.group(0).lower()], inner, flags=re.I)


def treatments(cid, acc):
    """Six icon variants per candidate: three treatments x (default, Increase Contrast).

    Returns list of (label, mark, field, field_stroke).
    For C the mark is drawn in ink; the accent only appears as the field in treatment 2.
    """
    if cid == "C":
        return [
            ("1 ink on white", C_INK["light"], "#FFFFFF", LIGHT_FIELD_STROKE),
            ("2 white on accent field", "#FFFFFF", acc["light"], acc["light"]),
            ("3 dark field, ink-dark mark", C_INK["dark"], DARK_FIELD, DARK_FIELD_STROKE),
            ("1-IC ink on white", C_INK["ic_light"], "#FFFFFF", LIGHT_FIELD_STROKE),
            ("2-IC white on IC-accent field", "#FFFFFF", acc["ic_light"], acc["ic_light"]),
            ("3-IC dark field, ink-dark mark", C_INK["ic_dark"], DARK_FIELD, DARK_FIELD_STROKE),
        ]
    return [
        ("1 accent on white", acc["light"], "#FFFFFF", LIGHT_FIELD_STROKE),
        ("2 white on accent field", "#FFFFFF", acc["light"], acc["light"]),
        ("3 dark field, accent-dark mark", acc["dark"], DARK_FIELD, DARK_FIELD_STROKE),
        ("1-IC IC-accent on white", acc["ic_light"], "#FFFFFF", LIGHT_FIELD_STROKE),
        ("2-IC white on IC-accent field", "#FFFFFF", acc["ic_light"], acc["ic_light"]),
        ("3-IC dark field, IC-dark mark", acc["ic_dark"], DARK_FIELD, DARK_FIELD_STROKE),
    ]


def filter_def(sim, w, h):
    if sim == "normal":
        return ""
    m = MATRICES[sim]
    vals = " ".join("%.6f %.6f %.6f 0 0" % tuple(r) for r in m) + " 0 0 0 1 0"
    # color-interpolation-filters is set DELIBERATELY to linearRGB: the Machado matrices and the
    # luminance weights are defined for linear-light RGB, not gamma-encoded sRGB values.
    return ('<defs><filter id="sim" filterUnits="userSpaceOnUse" x="0" y="0" width="%d" height="%d" '
            'color-interpolation-filters="linearRGB"><feColorMatrix type="matrix" values="%s"/></filter></defs>'
            % (w, h, vals))


def filtered_page(sim, w, h, parts):
    """Whole page (background, icons, swatches, labels) goes through the simulation filter."""
    return filter_def(sim, w, h) + '<g%s>%s</g>' % (' filter="url(#sim)"' if sim != "normal" else "", "".join(parts))


def text(x, y, s, size=18, fill="#3A3A3C", weight="400", anchor="start"):
    s = s.replace("&", "&amp;").replace("<", "&lt;")
    return ('<text x="%g" y="%g" font-size="%g" fill="%s" font-weight="%s" text-anchor="%s" %s>%s</text>'
            % (x, y, size, fill, weight, anchor, FONT, s))


def icon_at(root_attrs, inner, x, y, size):
    return '<svg x="%g" y="%g" width="%g" height="%g" %s>%s</svg>' % (x, y, size, size, root_attrs,
                                                                      uniquify_ids(inner))


def svg_doc(w, h, body):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>\n'
            % (w, h, w, h, body))


ICON = 240
GAP = 28
LEFT = 250
PAGE_BG = "#E9E9EC"  # neutral grey so both white-field and dark-field icons keep a visible edge


def icon_row(vb, inner, cid, acc, x0, y0):
    filtered, labels = [], []
    for i, (label, mark, field, stroke) in enumerate(treatments(cid, acc)):
        x = x0 + i * (ICON + GAP)
        filtered.append(icon_at(vb, recolor(inner, mark, field, stroke), x, y0, ICON))
        labels.append(text(x + ICON / 2, y0 + ICON + 22, label, 13, anchor="middle"))
    return filtered, labels


def build_strip(vb, inner, cand, sim, label):
    cid, name, acc = cand
    w = 40 + 6 * ICON + 5 * GAP + 40
    h = 70 + ICON + 40 + 24
    filt, labels = icon_row(vb, inner, cid, acc, 40, 70)
    body = ['<rect width="%d" height="%d" fill="%s"/>' % (w, h, PAGE_BG)]
    body.append(text(40, 32, "Candidate %s - %s" % (cid, name), 22, "#111111", "600"))
    body.append(text(40, 54, "%s  |  %s - colour evidence only, not a drawing review" % (SIM_LABEL[sim], label), 14))
    body.extend(filt)
    body.extend(labels)
    return svg_doc(w, h, filtered_page(sim, w, h, body)), w, h


SW = 96
SW_GAP = 10


PANEL_H = 40 + SW + 44
PANEL_GAP = 20


def swatch_panel(mode, x0, y0, pw):
    """Accent of every candidate next to the iOS status/system colours of the same appearance."""
    bg = BACKGROUNDS[mode][0]
    fg = "#111111" if mode in ("light", "ic_light") else "#F2F2F7"
    ph = PANEL_H
    filtered = ['<rect x="%g" y="%g" width="%g" height="%g" rx="18" fill="%s"/>' % (x0, y0, pw, ph, bg)]
    labels = [text(x0 + 18, y0 + 26, "%s - accents vs iOS system colours" % MODE_LABEL[mode], 15, fg, "600")]
    items = [(cid, acc[mode]) for cid, _, acc in CANDIDATES]
    items += [(STATUS_ROLE[k].split("/")[0].replace("system tint", "sys blue"), SYSTEM[mode][k]) for k in STATUS_ORDER]
    x = x0 + 18
    for i, (lab, col) in enumerate(items):
        if i == len(CANDIDATES):
            x += 22
        filtered.append('<rect x="%g" y="%g" width="%d" height="%d" rx="14" fill="%s"/>' % (x, y0 + 40, SW, SW, col))
        labels.append(text(x + SW / 2, y0 + 40 + SW + 16, lab, 12, fg, "600", "middle"))
        labels.append(text(x + SW / 2, y0 + 40 + SW + 32, col, 11, fg, "400", "middle"))
        x += SW + SW_GAP
    return filtered, labels, ph


def build_sheet(vb, inner, sim, label):
    n_swatches = len(CANDIDATES) + len(STATUS_ORDER)
    n_icons = len(treatments(CANDIDATES[0][0], CANDIDATES[0][2]))
    pw = 18 + n_swatches * (SW + SW_GAP) + 22 + 8
    w = max(LEFT + n_icons * ICON + (n_icons - 1) * GAP + 40, 40 + 2 * pw + 24 + 40)
    row_h = ICON + 50
    top = 96
    swatch_top = top + len(CANDIDATES) * row_h + 20
    filtered, labels = [], []
    for r, (cid, name, acc) in enumerate(CANDIDATES):
        y = top + r * row_h
        f, l = icon_row(vb, inner, cid, acc, LEFT, y)
        filtered += f
        labels += l
        labels.append(text(40, y + ICON / 2 - 8, "Candidate %s" % cid, 22, "#111111", "600"))
        labels.append(text(40, y + ICON / 2 + 16, name, 14))
    for i, mode in enumerate(MODES):
        px = 40 + (i % 2) * (pw + 24)
        py = swatch_top + (i // 2) * (PANEL_H + PANEL_GAP)
        f, l, _ = swatch_panel(mode, px, py, pw)
        filtered += f
        labels += l
    h = swatch_top + ((len(MODES) + 1) // 2) * (PANEL_H + PANEL_GAP) + 50
    body = ['<rect width="%d" height="%d" fill="%s"/>' % (w, h, PAGE_BG)]
    body.append(text(40, 44, "Calipic - accessibility & perception: %s" % SIM_LABEL[sim], 26, "#111111", "600"))
    body.append(text(40, 72, "%s - flat colour test of provisional palette values; geometry untouched; "
                             "evaluate colour, not drawing quality. No colour is approved (BD-033 open)." % label, 15))
    body.extend(filtered)
    body.extend(labels)
    body.append(text(40, h - 20, "Filter: feColorMatrix in linearRGB (color-interpolation-filters set explicitly). "
                                 "Simulations are approximations of dichromacy, not a substitute for user testing.",
                     13))
    return svg_doc(w, h, filtered_page(sim, w, h, body)), w, h


PROBE_CELL = 16


def probe_colors():
    cols = []
    for _, _, acc in CANDIDATES:
        cols += [acc[m] for m in MODES]
    for m in MODES:
        cols += [SYSTEM[m][k] for k in STATUS_ORDER]
    cols += [C_INK["light"], C_INK["dark"], DARK_FIELD, "#FFFFFF", "#000000"]
    return cols


def build_probe(sim):
    cols = probe_colors()
    w, h = PROBE_CELL * len(cols), PROBE_CELL
    rects = "".join('<rect x="%d" y="0" width="%d" height="%d" fill="%s"/>' % (i * PROBE_CELL, PROBE_CELL, PROBE_CELL, c)
                    for i, c in enumerate(cols))
    return svg_doc(w, h, filtered_page(sim, w, h, [rects])), w, h


def build(icon_path, out_dir, label):
    vb, inner = load_icon(icon_path)
    os.makedirs(out_dir, exist_ok=True)
    manifest = []

    def emit(name, png_rel, doc, w, h, kind):
        with open(os.path.join(out_dir, name), "w", encoding="utf-8") as fh:
            fh.write(doc)
        manifest.append("\t".join([kind, name, png_rel, str(w), str(h)]))

    for sim in SIMS:
        doc, w, h = build_sheet(vb, inner, sim, label)
        emit("sheet-%s.svg" % sim, "sheet-%s.png" % sim, doc, w, h, "sheet")
        for cand in CANDIDATES:
            doc, w, h = build_strip(vb, inner, cand, sim, label)
            emit("candidate-%s-%s.svg" % (cand[0], sim), "candidates/candidate-%s-%s.png" % (cand[0], sim),
                 doc, w, h, "strip")
        doc, w, h = build_probe(sim)
        emit("probe-%s.svg" % sim, "probe-%s.png" % sim, doc, w, h, "probe")
    with open(os.path.join(out_dir, "manifest.tsv"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(manifest) + "\n")


# --------------------------------------------------------------------------------------
# PNG decoding (stdlib) for verification
# --------------------------------------------------------------------------------------


def read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        sys.exit("error: %s is not a PNG" % path)
    pos, idat, w, h, bpp = 8, b"", 0, 0, 0
    while pos < len(data):
        (length,), ctype = struct.unpack(">I", data[pos:pos + 4]), data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            w, h, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
            if depth != 8 or color not in (2, 6) or interlace:
                sys.exit("error: unsupported PNG layout in %s (depth %d, colour type %d)" % (path, depth, color))
            bpp = 4 if color == 6 else 3
        elif ctype == b"IDAT":
            idat += chunk
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev = [], bytearray(stride)
    for y in range(h):
        ft = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if ft == 1:
                line[i] = (line[i] + a) & 255
            elif ft == 2:
                line[i] = (line[i] + b) & 255
            elif ft == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif ft == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        rows.append(line)
        prev = line
    return w, h, bpp, rows


def gamma_space_simulate(hex_color, sim):
    """What a renderer would produce if it WRONGLY applied the matrix to gamma-encoded sRGB values."""
    if sim == "normal":
        return hex_to_rgb(hex_color)
    m, rgb = MATRICES[sim], hex_to_rgb(hex_color)
    return tuple(min(255, max(0, int(round(sum(m[r][k] * rgb[k] for k in range(3)))))) for r in range(3))


def verify_probe(png, sim, max_de=5.0):
    """Compare rendered filter output with the exact computed simulation.

    Inkscape honours color-interpolation-filters=linearRGB but keeps 8-bit linear intermediates, so
    near-black tones are quantised (measured: up to ~8/255 per channel, dE00 up to ~4.1 for #1C1F24). The check is therefore
    perceptual (dE00 per colour) plus an aggregate test that the render is closer to the linear-RGB
    result than to the gamma-space one.
    """
    w, h, bpp, rows = read_png(png)
    cols = probe_colors()
    if w != PROBE_CELL * len(cols):
        sys.exit("error: probe width %d, expected %d" % (w, PROBE_CELL * len(cols)))
    worst_de, worst_ch, changed, err_lin, err_gam = 0.0, 0, 0, 0, 0
    for i, c in enumerate(cols):
        off = (i * PROBE_CELL + PROBE_CELL // 2) * bpp
        got = tuple(rows[h // 2][off:off + 3])
        want = hex_to_rgb(simulate(c, sim))
        gam = gamma_space_simulate(c, sim)
        err_lin += sum(abs(g - x) for g, x in zip(got, want))
        err_gam += sum(abs(g - x) for g, x in zip(got, gam))
        worst_ch = max(worst_ch, max(abs(g - x) for g, x in zip(got, want)))
        de = ciede2000(hex_to_lab(rgb_to_hex(got)), hex_to_lab(rgb_to_hex(want)))
        worst_de = max(worst_de, de)
        if got != hex_to_rgb(c):
            changed += 1
        if de > max_de:
            sys.exit("error: %s filter mismatch for %s: rendered %s, computed %s (dE00 %.1f)"
                     % (sim, c, rgb_to_hex(got), rgb_to_hex(want), de))
    if sim == "normal":
        if changed:
            sys.exit("error: unfiltered probe changed %d colours" % changed)
    else:
        if changed == 0:
            sys.exit("error: %s filter did not change any probe colour" % sim)
        if err_lin >= err_gam:
            sys.exit("error: %s render is closer to a gamma-space matrix than to linearRGB "
                     "(renderer ignoring color-interpolation-filters?)" % sim)
    print("  probe %-13s ok: %d colours, %d changed by filter, max dE00 vs computed %.2f "
          "(max channel error %d/255; summed error linear %d vs gamma-space %d)"
          % (sim, len(cols), changed, worst_de, worst_ch, err_lin, err_gam))


def verify_gray(bmp, tol=0):
    """Assert a rendered image has no chroma. Input is an uncompressed 24/32-bit BMP (the shell script
    converts the delivered full-resolution PNGs with sips) so the check is fast strided byte slicing."""
    d = open(bmp, "rb").read()
    if d[:2] != b"BM":
        sys.exit("error: %s is not a BMP" % bmp)
    (offset,) = struct.unpack("<I", d[10:14])
    _, w, h, _, bpp, comp = struct.unpack("<IiiHHI", d[14:34])
    if bpp not in (24, 32) or comp not in (0, 3):
        sys.exit("error: unsupported BMP layout in %s (bpp %d, compression %d)" % (bmp, bpp, comp))
    idx = [2, 1, 0]  # default BGR(A) byte order
    if comp == 3:
        masks = struct.unpack("<III", d[54:66])
        idx = [{0xFF: 0, 0xFF00: 1, 0xFF0000: 2, 0xFF000000: 3}.get(m) for m in masks]
        if None in idx:
            sys.exit("error: unsupported BMP channel masks in %s" % bmp)
    step = bpp // 8
    stride = (w * bpp + 31) // 32 * 4
    worst = 0
    for y in range(abs(h)):
        row = d[offset + y * stride: offset + y * stride + w * step]
        r, g, b = (row[i::step] for i in idx)
        if r != g or g != b:
            worst = max(worst, max(max(p) - min(p) for p in zip(r, g, b)))
    if worst > tol:
        sys.exit("error: %s contains chroma (max channel spread %d)" % (bmp, worst))
    print("  grayscale check ok: %s (%dx%d full resolution, max channel spread %d)"
          % (os.path.basename(bmp), w, abs(h), worst))


# --------------------------------------------------------------------------------------
# Tables
# --------------------------------------------------------------------------------------

DE_CONFUSABLE, DE_CLOSE = 10.0, 20.0


def flag_contrast(v):
    if v < 3.0:
        return "%.2f **FAIL <3**" % v
    if v < 4.5:
        return "%.2f *<4.5*" % v
    return "%.2f" % v


def flag_de(v):
    if v < DE_CONFUSABLE:
        return "**%.1f !!**" % v
    if v < DE_CLOSE:
        return "*%.1f !*" % v
    return "%.1f" % v


def tables(out_path):
    o = []
    o.append("<!-- Generated by scripts/brand/render-a11y.sh (a11y_tools.py tables). Do not edit by hand. -->")
    o.append("")
    o.append("#### T1 - WCAG 2.x contrast ratios")
    o.append("")
    o.append("`*<4.5*` = below AA for normal text (still >= 3:1: large text / non-text UI only). "
             "`**FAIL <3**` = below the 3:1 minimum for non-text UI components and large text.")
    o.append("")
    o.append("| Cand. | Appearance | Value | vs bg 1 | vs bg 2 | White `#FFFFFF` label on accent | "
             "Black `#000000` label on accent |")
    o.append("|---|---|---|---|---|---|---|")
    rows = []
    for cid, _, acc in CANDIDATES:
        for m in MODES:
            rows.append((cid + " accent", m, acc[m]))
        if cid == "C":
            for m in ("light", "dark"):
                rows.append(("C ink", m, C_INK[m]))
    for who, m, val in rows:
        b1, b2 = BACKGROUNDS[m]
        o.append("| %s | %s | `%s` | %s (`%s`) | %s (`%s`) | %s | %s |" % (
            who, MODE_LABEL[m], val, flag_contrast(contrast(val, b1)), b1, flag_contrast(contrast(val, b2)), b2,
            flag_contrast(contrast("#FFFFFF", val)), flag_contrast(contrast("#000000", val))))
    o.append("")
    o.append("Reference rows (iOS system colours, same maths):")
    o.append("")
    o.append("| System colour | Appearance | Value | vs bg 1 | vs bg 2 | White label on it |")
    o.append("|---|---|---|---|---|---|")
    for m in ("light", "dark"):
        for k in STATUS_ORDER:
            val = SYSTEM[m][k]
            b1, b2 = BACKGROUNDS[m]
            o.append("| %s (%s) | %s | `%s` | %s | %s | %s |" % (
                k, STATUS_ROLE[k], MODE_LABEL[m], val, flag_contrast(contrast(val, b1)),
                flag_contrast(contrast(val, b2)), flag_contrast(contrast("#FFFFFF", val))))
    o.append("")

    o.append("#### T2 - Icon-treatment contrast (mark vs field)")
    o.append("")
    o.append("| Cand. | Treatment | Mark | Field | Contrast |")
    o.append("|---|---|---|---|---|")
    for cid, _, acc in CANDIDATES:
        for label, mark, field, _ in treatments(cid, acc):
            o.append("| %s | %s | `%s` | `%s` | %s |" % (cid, label, mark, field, flag_contrast(contrast(mark, field))))
    o.append("")

    o.append("#### T3 - Minimal value adjustments for accents below 4.5:1 on their system backgrounds")
    o.append("")
    o.append("Computed, not hand-picked: CIELAB L* is moved away from the background (lowered for light appearances, "
             "raised for dark ones) in 0.25 steps with a*, b* held (hue and chroma "
             "approximately preserved; out-of-gamut results are clipped) until the target is met against BOTH "
             "system backgrounds. These are proposals for the next test round, not decisions.")
    o.append("")
    o.append("| Cand. | Appearance | Current | Worst bg contrast | Proposed for >= 4.5:1 | Contrast after (bg1 / bg2) | "
             "dE00 current -> proposed |")
    o.append("|---|---|---|---|---|---|---|")
    for cid, _, acc in CANDIDATES:
        for m in MODES:
            bgs = BACKGROUNDS[m]
            worst = min(contrast(acc[m], bg) for bg in bgs)
            if worst >= 4.5:
                continue
            prop = adjust_for_contrast(acc[m], bgs, 4.5)
            if prop is None:
                o.append("| %s | %s | `%s` | %.2f | none found | - | - |" % (cid, MODE_LABEL[m], acc[m], worst))
                continue
            o.append("| %s | %s | `%s` | %.2f | `%s` | %.2f / %.2f | %.1f |" % (
                cid, MODE_LABEL[m], acc[m], worst, prop, contrast(prop, bgs[0]), contrast(prop, bgs[1]),
                delta_e(acc[m], prop)))
    o.append("")
    o.append("White-label-on-accent (filled button) adjustments, light appearance only - same method, target "
             "4.5:1 for a `#FFFFFF` label:")
    o.append("")
    o.append("| Cand. | Current | White-label contrast | Proposed | White-label contrast after |")
    o.append("|---|---|---|---|---|")
    for cid, _, acc in CANDIDATES:
        cur = contrast("#FFFFFF", acc["light"])
        if cur >= 4.5:
            o.append("| %s | `%s` | %.2f | (passes) | - |" % (cid, acc["light"], cur))
        else:
            prop = adjust_for_contrast(acc["light"], ["#FFFFFF"], 4.5, direction=-1)
            if prop is None:
                o.append("| %s | `%s` | %.2f | none found | - |" % (cid, acc["light"], cur))
                continue
            o.append("| %s | `%s` | %.2f | `%s` | %.2f |" % (cid, acc["light"], cur, prop, contrast("#FFFFFF", prop)))
    o.append("")

    o.append("#### T4 - CIEDE2000 colour difference: accent vs iOS status/system colours")
    o.append("")
    o.append("dE00 between each accent and the system colour of the SAME appearance, under normal vision and each "
             "simulation. Heuristic flags (not a standard): `**x !!**` = dE00 < %g (likely confusable as flat "
             "swatches), `*x !*` = dE00 < %g (close; needs shape/label redundancy). The Grayscale column is "
             "informational only and is neither flagged nor included in Min: with chroma removed, dE00 reduces to "
             "a lightness difference, and the iOS status colours collide with EACH OTHER there too (see T4-ref), "
             "which is why colour may never be the only status signal. CIEDE2000 was designed for SMALL "
             "differences and compresses large chroma differences, especially in the blue region, so the Min "
             "column also quotes the plain CIE76 Lab distance of the same pair: a low dE00 with a high dE76 "
             "(e.g. a greyed blue vs saturated system blue) is a same-hue-family warning, not a claim that the "
             "two swatches look alike." % (DE_CONFUSABLE, DE_CLOSE))
    o.append("")
    for m in MODES:
        o.append("**%s**" % MODE_LABEL[m])
        o.append("")
        o.append("| Cand. | Accent | vs | " + " | ".join(s.capitalize() for s in SIMS) + " | Min (excl. grayscale) |")
        o.append("|---|---|---|" + "---|" * (len(SIMS) + 1))
        for cid, _, acc in CANDIDATES:
            for k in STATUS_ORDER:
                vals = {s: delta_e(acc[m], SYSTEM[m][k], s) for s in SIMS}
                o.append("| %s | `%s` | %s `%s` (%s) | %s | %s |" % (
                    cid, acc[m], k, SYSTEM[m][k], STATUS_ROLE[k],
                    " | ".join(("%.1f" % vals[s]) if s == "grayscale" else flag_de(vals[s]) for s in SIMS),
                    min_cell(acc[m], SYSTEM[m][k])))
        o.append("")

    o.append("#### T4-ref - Baseline: iOS system colours against each other (same maths)")
    o.append("")
    o.append("Context for reading T4: Apple's own status palette already contains pairs that are close under "
             "dichromacy simulation.")
    o.append("")
    o.append("| Appearance | Pair | " + " | ".join(s.capitalize() for s in SIMS) + " | Min (excl. grayscale) |")
    o.append("|---|---|" + "---|" * (len(SIMS) + 1))
    for m in ("light", "dark"):
        for i, k1 in enumerate(STATUS_ORDER):
            for k2 in STATUS_ORDER[i + 1:]:
                vals = {s: delta_e(SYSTEM[m][k1], SYSTEM[m][k2], s) for s in SIMS}
                o.append("| %s | %s vs %s | %s | %s |" % (
                    MODE_LABEL[m], k1, k2,
                    " | ".join(("%.1f" % vals[s]) if s == "grayscale" else flag_de(vals[s]) for s in SIMS),
                    min_cell(SYSTEM[m][k1], SYSTEM[m][k2])))
    o.append("")

    o.append("#### T5 - Simulated appearance of each accent (hex after simulation)")
    o.append("")
    o.append("| Cand. | Appearance | " + " | ".join(s.capitalize() for s in SIMS) + " |")
    o.append("|---|---|" + "---|" * len(SIMS))
    for cid, _, acc in CANDIDATES:
        for m in MODES:
            o.append("| %s | %s | %s |" % (cid, MODE_LABEL[m], " | ".join("`%s`" % simulate(acc[m], s) for s in SIMS)))
    o.append("")
    o.append("#### T6 - Worst-case separation per candidate (normal vision + 3 CVD simulations, all appearances)")
    o.append("")
    o.append("| Cand. | Closest status/system colour over all appearances and simulations | dE00 | dE76 |")
    o.append("|---|---|---|---|")
    for cid, _, acc in CANDIDATES:
        best = None
        for m in MODES:
            for k in STATUS_ORDER:
                for s in COLOUR_SIMS:
                    v = delta_e(acc[m], SYSTEM[m][k], s)
                    if best is None or v < best[0]:
                        best = (v, m, k, s)
        o.append("| %s | %s (%s), %s, %s | %s | %.0f |" % (
            cid, best[2], STATUS_ROLE[best[2]], MODE_LABEL[best[1]], best[3], flag_de(best[0]),
            delta_e76(acc[best[1]], SYSTEM[best[1]][best[2]], best[3])))
    o.append("")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(o))


BEGIN, END = "<!-- BEGIN GENERATED TABLES -->", "<!-- END GENERATED TABLES -->"


def inject(doc_path, frag_path):
    doc = open(doc_path, encoding="utf-8").read()
    frag = open(frag_path, encoding="utf-8").read().rstrip("\n")
    if BEGIN not in doc or END not in doc:
        sys.exit("error: %s lacks the generated-table markers" % doc_path)
    head, rest = doc.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    new = head + BEGIN + "\n" + frag + "\n" + END + tail
    if new != doc:
        with open(doc_path, "w", encoding="utf-8") as fh:
            fh.write(new)


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    cmd, args = argv[1], argv[2:]
    if cmd == "selftest" and not args:
        selftest()
    elif cmd == "build" and len(args) == 3:
        build(*args)
    elif cmd == "tables" and len(args) == 1:
        tables(args[0])
    elif cmd == "inject" and len(args) == 2:
        inject(*args)
    elif cmd == "verify-probe" and len(args) == 2:
        verify_probe(*args)
    elif cmd == "verify-gray" and len(args) == 1:
        verify_gray(args[0])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
